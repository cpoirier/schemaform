#!/usr/bin/env ruby
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2012 Chris Poirier
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

require Schemaform.locate("relation.rb")


#
# Represents a single SQL query and provides methods for creating a more complex one from it.

module Schemaform
module Adapters
module GenericSQL
class Query < Relation
   
   def initialize( relation )
      super(relation.adapter)

      @fields           = {}          # name  => Field
      @sources          = {}          # alias => Source
      @where_condition  = nil
      @group_by_fields  = nil
      @having_condition = nil
      @order_by_fields  = nil
      @offset           = 0
      @limit            = 0
      @has_aggregates   = false

      add_source!(build_from(relation))
   end
   
   attr_reader :fields, :sources, :where_condition, :group_by_fields, :having_condition, :order_by_fields, :offset, :limit
   
   def field_names()
      @fields.keys
   end

   def simple?()
      !@group_by_fields.exists? && !@has_aggregates && @limit <= 0 && !@order_by_fields.exists?
   end


   # ==========================================================================================
   # Naming operations
   
   def project( mappings )
      fields = {}
      mappings.each do |from, to|
         fields[to.to_s] = @fields[from.to_s]
      end
      
      (simple? ? dup() : self.class.new(self)).use do |result|
         result.instance_eval{@fields = fields}
      end
   end
   
   def select( *names )
      project(names.to_hash(:value_is_key))
   end
   
   def discard( *names )
      select(field_names - names)
   end
   
   def rename( from_or_mappings, to = nil )
      mappings = field_names.to_hash(:value_is_key)
      mappings.merge!(from_or_mappings.is_a?(Hash) ? from_or_mappings : {from_or_mappings => to})
      project(mappings)
   end
   
   def prefix( prefix, *names )
      mappings = {}
      field_names.each do |field_name|
         mappings[field_name] = (names.empty? || names.member?(field_name)) ? sprintf("%s%s", prefix, field_name) : field_name
      end
      project(mappings)
   end



   # =======================================================================================
   #                                   Relational Operations
   # =======================================================================================

   def where( expression )
      dup.use do |result|
         if expression.is_a?(Hash) then
            found = expression.keys.select{|k| @fields.member?(k.to_s)}
            assert(found.length == expression.length, "where set references non-existent fields")

            comparisons = expression.collect do |k, v|
               field = @fields[k.to_s]
               build_comparison(field, build_literal(field.type_info, v))
            end

            result.and_where!(build_and(comparisons))
         else
            result.and_where!(expression)
         end
         
         Schemaform.debug.dump(result, "AFTER WHERE: ")
      end
   end
   
   
   def join( rhs, condition = nil, type = nil )
      rhs.is_a?(Query) or rhs = self.class.new(rhs)
      
      dup.use do |result|
         if rhs.sources.length == 1 && !rhs.has_aggregates && rhs.group_by_fields.empty? && rhs.offset == 0 && rhs.limit == 0 then
            fail_todo "join on simple rhs"
            join = Join.new(self, rhs.sources[rhs.sources.keys.first], condition)
            result.add_source!(join, false)
         else
            result.add_source!(Join.new(self, rhs, condition, type))
         end
      end
   end
   
   
   
   # =======================================================================================
   #                                   SQL Generation
   # =======================================================================================

   
   def to_s()
      @sql ||= print_to(Printer.new()).to_s()
   end
   
   alias to_str to_s
   
   def print_to( printer )
      printer << "SELECT "
            
      first = true
      @fields.each do |name, definition|
         first or printer << ", " and first = false
         definition.print_to(printer)
         printer << " as #{name}" unless definition.responds_to?(:field_name) && definition.field_name == name
      end
      
      @sources.each do |name, source|
         printer.end_line()
         source.print_to(printer)
      end
      
      if @where_condition.exists? then
         printer.end_line()
         printer << "WHERE "
         @where_condition.print_to(printer)
      end

      if @group_by_fields.exists? then
         printer.end_line()
         printer << "GROUP BY "
         
         first = true
         @group_by_fields.each do |name|
            first or printer << ", " and first = false
            @fields[name].print_to(printer)
         end
      end
      
      if @order_by_fields.exists? then
         printer.end_line()
         printer << "ORDER BY "
         
         first = true
         @order_by_fields.each do |name|
            first or printer << ", " and first = false
            if name.is_a?(Numeric) then
               printer << " DESC" if name == -1
            else
               printer << name
            end
         end
      end
      
      if @limit > 0 then
         printer.end_line()
         printer << (@offset > 0 ? sprintf("LIMIT %d, %d", @offset, @limit) : sprintf("LIMIT %d", @limit))
      end
      
      printer.end_line
      
      return printer
   end
   


   # =======================================================================================
   #                                   Object Instantiation
   # =======================================================================================


   def build_field_reference( source, name, type_info )
      QueryParts::FieldReference.new(type_info, source, name)
   end
   
   def build_derived_field( type_info, expression )
      QueryParts::DerivedField.new(type_info, expression)
   end
   
   def build_and( *clauses )
      QueryParts::And.new(@adapter.type_manager.boolean_type, *clauses)
   end
   
   def build_or( *clauses )
      QueryParts::Or.new(@adapter.type_manager.boolean_type, *clauses)
   end
   
   def build_not( expression )
      QueryParts::Not.new(@adapter.type_manager.boolean_type, expression)
   end
      
   def build_comparison( lhs, rhs, op = "=" )
      QueryParts::Comparison.new(@adapter.type_manager.boolean_type, op, lhs, rhs)
   end
   
   def build_literal( type_info, value )
      QueryParts::Literal.new(type_info, value)
   end
   
   def build_from( relation )
      QueryParts::From.new(self, relation)
   end
   
   def build_join( relation, condition, type = nil )
      QueryParts::Join.new(self, relation, condition, type)
   end

   

protected

   # =======================================================================================
   #                                       Internals
   # =======================================================================================

   def add_source!( source, import_fields = true )
      type_check(:source, source, QueryParts::Source)
      source.alias = "t#{@sources.length + 1}"
      @sources[source.alias] = source

      if import_fields then
         source.fields.each do |name, field|
            name = name.to_s
            unless @fields.member?(name)
               @fields[name] = build_field_reference(source, name, field.type_info)
            end
         end
      end
      
      source.alias
   end
   
   def and_where!( expression )
      if @where_condition then
         @where_condition = build_and(@where_condition, expression)
      else
         @where_condition = expression
      end
      
      self
   end
   
   
   
end # Query
end # GenericSQL
end # Adapters
end # Schemaform

Dir[Schemaform.locate("query_parts/*.rb")].each{|path| require path}

