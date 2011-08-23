#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
# [License]   Licensed under the Apache License, Version 2.0 (the "License");
#             you may not use this file except in compliance with the License.
#             You may obtain a copy of the License at
#             
#                 http://www.apache.org/licenses/LICENSE-2.0
#             
#             Unless required by applicable law or agreed to in writing, software
#             distributed under the License is distributed on an "AS IS" BASIS,
#             WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#             See the License for the specific language governing permissions and
#             limitations under the License.
# =============================================================================================


#
# Captures informtion about how a Schema::Entity is mapped into Tables and Fields.

module Schemaform
module Adapters
module Generic
class EntityMap
   include QualityAssurance
   
   Link    = Struct.new(:from_table, :to_table, :via, :skipped)
   Mapping = Struct.new(:attribute, :property, :field)

   def initialize( schema_map, entity, anchor_table, base_map = nil )
      @schema_map     = schema_map
      @entity         = entity
      @anchor_table   = anchor_table
      @tables         = [anchor_table]
      @base_map       = base_map || @schema_map[entity.base_entity]
      @parent_links   = {}                                  # child Table => Link
      @all_links      = Hash.new(){|h, k| h[k] = {}}        # descendent Table => { ancestor Table => Link }
      @mappings       = Hash.new(){|h, k| h[k] = {}}        # Schema::Attribute => { aspect => Field }
      @sources        = {}                                  # Field => source Field
      @copies         = Hash.new(){|h, k| h[k] = []}        # source Field => [all copies]
      @schema_map.register_table(anchor_table)
   end

   attr_reader :schema_map, :entity, :anchor_table, :base_map

   def link_child_to_parent( reference_field )
      child_table  = reference_field.table
      parent_table = reference_field.reference_mark.table
      link         = Link.new(child_table, parent_table, reference_field, [])
      
      @parent_links[child_table]            = link
      @all_links[child_table][parent_table] = link

      @tables << child_table
      @schema_map.register_table(child_table)
   end
   
   def link_child_to_context( reference_field )
      child_table   = reference_field.table
      context_table = referenced_field.reference_mark.table

      skipped = []
      current_table = child_table
      while hit = @parent_links[current_table]
         break if hit.to_table == context_table
         skipped << current_table
      end
      
      if hit then
         @all_links[child_table][context_table] = Link.new(child_table, context_table, reference_field, skipped)
      else
         fail "couldn't find context path from [#{child_table.name}] to [#{context_table.name}]"
      end
   end
   
   def link_field_to_attribute( field, attribute, aspect )
      @mappings[attribute][aspect] = field
   end
   
   def link_field_to_source( field, source_field )
      @sources[field] = source_field
      while source_field
         @copies[source_field] << field
         source_field = @sources[source_field]
      end
   end
   
   def get_field_for_attribute( attribute, aspect = Language::Productions::ValueAccessor )
      attribute = @entity.find(attribute.attribute_path) if attribute.root_tuple.context != @entity
      
      return @mappings[attribute][aspect] if @mappings.member?(attribute)
      return @base_map.get_field_for_attribute(attribute, aspect) if @base_map
      return nil
   end

   def build_query( predicate, projection )
      Printer.dump(predicate)
      
      fail_todo
      
   end
   # 
   # def project( expressions )
   #    productions = expressions.collect{|e| e.production}
   #    all_fields  = productions.collect{|p| @mappings[p.attribute.get_definition][p.class]}.flatten.uniq.compact
   #    
   #    #
   #    # First up, find the way to pull the data from as few tables as possible, via the use of field equivalencies.
   #    # For the most part, this will be about substituting references for identifiers, but could also involve 
   #    # cache tables that collect pieces of data from the Entity in one place.
   #    
   #    
   #    
   #    
   #    
   #    
   # 
   #    #
   #    # First up, see what we can do with just the data fields. We can just as easily use an identifier
   #    # via a reference to it as we can by including the table where the identifier lives. If we can avoid
   #    # adding extra tables to the join, we should.
   #    
   #    data_fields = all_fields - @tables.collect{|table| table.identifier}
   #    id_fields   = all_fields - data_fields
   #    data_tables = data_fields.collect{|f| f.table}.flatten.uniq
   #    join_plan   = plan_join(data_tables)
   #    
   #    
   #    
   #    
   #    
   #    data_tables
   #    
   #    fail_todo
   # end
   


protected
   
   def plan_join( tables )
      JoinPlanner.new(tables, @all_links)
   end
   
   #
   # Captures a mapping of a Field from internal to external space.
   
   class FieldMapping
      def initialize( internal, external )
         @internal = internal
         @external = external
      end
      
      attr_reader :internal, :external
      
      def eql?( rhs )
         if rhs.is_a?(Field) then
            @internal == rhs || @external == rhs
         else
            @internal == rhs.internal && @external == rhs.external
         end
      end
   end
   
   
   #
   # Used by the EntityMap to figure out the minimal set of tables needed for a particular projection,
   # and how to join them together.
   
   class JoinPlanner
      include QualityAssurance
      
      def initialize( required_tables, all_links )
         @required_tables = required_tables
         @tree = ArrayHash.new()

         #
         # Load the tree from the master path list.

         queue = [] + required_tables
         while from_table = queue.shift
            unless @tree.member?(from_table)
               all_links[from_table].each do |to_table, link|
                  if (link.skipped & @required_tables).empty? then  # We can immediately ignore any links that would skip required tables.
                     @tree[from_table] << link
                     queue << to_table
                  end
               end
            end
         end

         #
         # Sort the links so the ones with the most skipped tables are first. 

         @tree.each do |table, links|
            links.sort!{|a, b| b.skipped.length <=> a.skipped.length}
         end

         #
         # Simplify paths where there are multiple choices. 

         @required_tables.each do |required_table|
            other_tables = @required_tables - [required_table]
            simplify_path(required_table, other_tables)
         end

         #
         # Pick the minimum table set from the tree.

         @minimum_set = [] + @required_tables
         @apex = nil

         current_table = @required_tables.first
         other_tables  = @required_tables.rest

         while current_table
            @minimum_set << current_table unless @minimum_set.member?(current_table)
            if other_tables.all?{|other_table| path_can_reach?(current_table, other_table)} then
               @apex = current_table if @apex.nil?
               current_table = other_tables.shift
            elsif links = @tree[current_table] then
               current_table = links.first.to_table
            else
               fail "can this happen?"
            end
         end
      end

      attr_reader :minimum_set, :apex

      def apex_is_optional?()
         !@required_tables.member?(@apex)
      end

   protected

      def path_can_reach?( point, from )
         !path_can_skip?(point, from)
      end


      def path_can_skip?( point, from )
         return false if point == from
         return true  if @tree[from].empty?
         return @tree[from].any? do |link|
            path_can_skip?(point, link.to_table)
         end
      end

      def simplify_path( position, relative_roots )
         while position
            links = @tree[position]
            case links.length
            when 0
               position = nil                    # End of the path; we're done
            when 1
               position = links.first.to_table   # Already simple; keep going
            else

               #
               # We have a choice to make. We want the longest path that doesn't skip stuff
               # needed by the relative_roots. Note: we have already sorted the links longest
               # first.

               best_choice = links.select_first do |link|
                  link.skipped.all? do |skipped|
                     relative_roots.all? do |root|
                        path_can_skip?(skipped, root)
                     end
                  end
               end

               if best_choice then
                  @tree[position] = [best_choice]
                  position = best_choice.to_table   # Now simple; keep going
               else
                  fail_todo "I'm too tired of this problem to figure out what this means now."
               end
            end
         end
      end
   end

      
   

end # EntityMap
end # Generic
end # Adapters
end # Schemaform

