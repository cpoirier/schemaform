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
# Adds schema building code to the Adapter.

module Schemaform
module Adapters
module GenericSQL
class Adapter
   
   #
   # Retrieves the EntityMap for the specified Entity.
   
   def map_entity( entity )
      lay_out(entity.schema) unless @entity_maps.member?(entity)
      return @entity_maps.fetch(entity)
   end
   
   
   #
   # Checks if the specified Schema has been laid out.
   
   def laid_out?( definition )
      @schema_maps.member?(definition)
   end
   
   
   #
   # Lays out a Schema for use with the database. 
   
   def lay_out( definition )
      @monitor.synchronize do
         unless @schema_maps.member?(definition)
            schema_name = Name.build(*definition.path)
            @schema_maps[definition] = SchemaMap.new(self, definition).tap do |schema_map|

               #
               # Create anchor tables and entity maps for each DefinedEntity first. We need them in place 
               # for reference resolution.

               definition.defined_entities.each do |entity|
                  schema_map.map(entity, define_table(schema_name + entity.name)) do |entity_map, table|
                     id_name = Name.build("", "id")
                     
                     if entity.base_entity.exists? then
                        base_map   = schema_map[entity.base_entity]
                        base_table = base_map.anchor_table
                        base_id    = base_table.identifier
                        
                        table.identifier = table.define_reference_field(id_name, entity_map.base_map.anchor_table, build_primary_key_mark())
                        entity_map.link_child_to_parent(table.identifier)
                     else
                        table.identifier = table.define_identifier_field(id_name, build_primary_key_mark())
                     end
                  end
               end

               #
               # Now, fill them in with the basic data structure.

               definition.defined_entities.each do |entity|
                  builder = @overrides.fetch(:lay_out_builder_class, LayOutBuilder).new(self, schema_map.entity_maps[entity])

                  entity.heading.attributes.each do |attribute|
                     next if entity.base_entity.exists? && entity.base_entity.heading.attribute?(attribute.name)

                     dispatch(:lay_out, attribute, builder)
                  end
                  
                  entity.keys.each do |key|
                     builder.build_key(key)
                  end
               end
            end
         end
      end
      
      @schema_maps[definition]
   end


   def lay_out_attribute( attribute, builder, before = true )
      builder.with_attribute(attribute) do
         yield if block_given? && before
         send_specialized(:lay_out, attribute.type, builder)
         yield if block_given? && !before
      end
   end
   
   def lay_out_optional_attribute( attribute, builder )
      lay_out_attribute(attribute, builder, true) do
         builder.define_meta(Language::Productions::PresentCheck, "?", type_manager.boolean_type, build_required_mark())
      end
   end
   
   def lay_out_volatile_attribute( attribute, builder )
      warn_todo("what do we do about mapping volatile attributes?")
   end
   
   
   
   def lay_out_tuple( tuple, builder )
      tuple.attributes.each do |attribute|
         dispatch(:lay_out, attribute, builder)
      end
   end
   
   
   def lay_out_type( type, builder )
      fail "no lay_out support for #{type.class.name}"
   end

   def lay_out_entity_reference_type( type, builder )
      warn_todo("reference field null/default handling")
      
      referenced_entity_map = builder[type.referenced_entity] or fail "couldn't resolve a reference to entity [#{type.entity_name}]"

      marks = []
      marks << (builder.current_optionality ? OptionalMark.new() : RequiredMark.new())
      marks << build_reference_mark(referenced_entity_map.anchor_table, true)
      
      builder.define_scalar(type_manager.identifier_type, *marks)
   end

   def lay_out_scalar_type( type, builder )
      builder.define_scalar(type_manager.scalar_type(type))
   end

   def lay_out_tuple_type( type, builder )
      dispatch(:lay_out, type.tuple, builder)
   end
   
   def lay_out_user_defined_type( type, builder )
      dispatch(:lay_out, type.base_type, builder)
   end

   def lay_out_unknown_type( type, builder )
      fail
   end
   

   def lay_out_collection_type( type, builder, purpose = nil, default_name = "" )
      builder.define_child_table(true, default_name, purpose) do
         yield if block_given?
      end
   end
   
   def lay_out_collection_type__member_type( member_type, builder )
      if member_type.naming_type? then
         dispatch(:lay_out, member_type, builder)
      else
         builder.with_name("value") do
            dispatch(:lay_out, member_type, builder)
         end
      end
   end
   
   def lay_out_set_type( type, builder )
      lay_out_collection_type(type, builder, "set") do
         lay_out_collection_type__member_type(type.member_type, builder)
      end
   end
   
   def lay_out_list_type( type, builder )      
      field_type       = type_manager.identifier_type
      member_reference = nil

      lay_out_collection_type(type, builder, "list") do
         member_reference = build_reference_mark(builder.current_table)
         lay_out_collection_type__member_type(type.member_type, builder)

         warn_once("list meta fields cannot be completed until Productions exist for accessing them")
         # builder.define_meta(AttributeAspects::ListMemberNextMember, "next"    , field_type, member_reference)
         # builder.define_meta(AttributeAspects::ListMemberPreviousMember, "previous", field_type, member_reference)
      end

      warn_once("list meta fields cannot be completed until Productions exist for accessing them")
      # builder.define_meta(AttributeAspects::ListFirstMember, "first", field_type, member_reference)
      # builder.define_meta(AttributeAspects::ListLastMember , "last" , field_type, member_reference)
   end





   #
   # Lay out builder used by the lay_out*() routines to ensure both Tables and EntityMaps are built in 
   # step. If you need to change this, be sure to pass the class as :lay_out_builder_class in the Adapter 
   # overrides.
   
   class LayOutBuilder
      include QualityAssurance
      TableFrame     = Struct.new(:table, :default_name, :name_stack, :current_optionality)
      AttributeFrame = Struct.new(:attribute, :aspect)
      
      
      def initialize( adapter, entity_map )
         @adapter         = adapter
         @entity_map      = entity_map
         @schema_map      = entity_map.schema_map
         @table_stack     = [TableFrame.new(entity_map.anchor_table, @adapter.build_name(), [], false)]
         @attribute_stack = []
      end
      
      def []( entity )
         @schema_map[entity]
      end
      
      def current_table()
         @table_stack.top.table
      end
      
      def current_attribute()
         @attribute_stack.top.attribute
      end
      
      def current_optionality()
         @table_stack.top.current_optionality
      end
      
      def with_attribute( attribute )
         @attribute_stack.push_and_pop(AttributeFrame.new(attribute, Language::Productions::ValueAccessor)) do
            @table_stack.top.current_optionality = attribute.is_a?(Schema::OptionalAttribute)
            name_stack.push_and_pop((name_stack.top || @adapter.build_name()) + attribute.name) do
               yield
            end
         end
      end
      
      def with_meta( aspect, name )
         @attribute_stack.push_and_pop(AttributeFrame.new(@attribute_stack.top.attribute, aspect)) do
            name_stack.push_and_pop((name_stack.top || @table_stack.top.default_name) + name) do
               yield
            end
         end
      end
      
      def with_name( name )
         name_stack.push_and_pop((name_stack.top || @table_stack.top.default_name) + name) do
            yield
         end
      end

      def define_scalar( type_info, *field_marks )
         @table_stack.top.table.define_field(name_stack.top, type_info, *field_marks).tap do |field|
            frame = @attribute_stack.top
            @entity_map.link_field_to_attribute(field, frame.attribute, frame.aspect)
            @entity_map.link_field_to_source(field, field.referenced_field) if field.reference?
         end
      end
      
      def define_meta( purpose, name, type_info, *field_marks )
         with_meta(purpose, name) do
            define_scalar(type_info, *field_marks)
         end
      end
      
      #
      # Creates a child table to the current table. Any block you pass will be processed with the
      # new table on the top of the stack.
      
      def define_child_table( has_many, default_name = "", context = "owner" )
         parent_table = @table_stack.top.table
         default_name = @adapter.build_name(default_name)
         
         @adapter.define_table(parent_table.name + name_stack.top) do |table|
            if has_many then
               table.identifier = table.define_identifier_field(default_name + "id", @adapter.build_primary_key_mark())
            end

            #
            # Link to the direct owner. For tuple-valued children, this will also be the primary key.
            
            owner_field = table.define_reference_field(default_name + "#{context}_id" , parent_table)
            @entity_map.link_child_to_parent(owner_field)
            @entity_map.link_field_to_source(owner_field, owner_field.referenced_field)

            unless has_many
               table.identifier = owner_field
               owner_field.marks << @adapter.build_primary_key_mark()
            end
            
            #
            # Link to the root, if not directly linked. This can be used to quickly identify all
            # children of a root-level object being retrieved/changed/deleted.
            
            if parent_table != @entity_map.anchor_table then
               context_field = table.define_reference_field(default_name + "root", @entity_map.anchor_table)
               @entity_map.link_child_to_context(context_field)
               @entity_map.link_field_to_source(context_field, context_field.referenced_field)
            end
            
            #
            # Update the table stack.
            
            @table_stack.push_and_pop(TableFrame.new(table, default_name, [])) do
               yield
            end
         end
      end
      
      def build_key( definition )
         key_name = "ck_" + definition.name.to_s
         fields   = definition.attributes.collect{|attribute| @entity_map.get_field_for_attribute(attribute, Language::Productions::ValueAccessor)}
         
         if fields.all?{|field| field.type.indexable?} then
            tables = fields.collect{|field| field.table}.uniq
            if tables.length == 1 then
               tables.first.define_index(key_name, true) do |index|
                  fields.each do |field|
                     index.add_field(field)
                  end
               end
            else
               assert(@table_stack.length == 1, "keys should not be defined within an attribute context")
               with_name(name) do 
                  parent_table = @table_stack.top.table
                  @adapter.define_table(parent_table.name + name_stack.top) do |table|
                     table.define_index("owner") do |owner_index| 
                        table.define_reference_field(default_name + "owner", parent_table).tap do |owner_field|
                           owner_index.add_field(owner_field)
                           @entity_map.link_child_to_parent(owner_field)
                           @entity_map.link_field_to_source(owner_field, owner_field.referenced_field)
                        end
                     end

                     table.define_index("pk", true) do |primary_key|
                        fields.each do |field|
                           table.define_field(field.table.name + field.name, field.type, field.marks.collect{|mark| mark.dup}).tap do |copy|
                              primary_key.add_field(copy)
                              @entity_map.link_field_to_source(copy, field)
                           end
                        end
                     end
                  end
               end
            end
         else
            warn("skipping non-indexable key (#{definition.full_name})", "TODO")
         end
      end
      
      
      
   protected
      def name_stack()
         @table_stack.top.name_stack
      end
      
   end



end # Adapter
end # GenericSQL
end # Adapters
end # Schemaform
