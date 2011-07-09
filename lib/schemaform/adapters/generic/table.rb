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

require Schemaform.locate("component.rb")


#
# A table, possibly nested, (for naming purposes only). 

module Schemaform
module Adapters
module Generic
class Table < Component

   def initialize( context, name, id_name = nil, id_table = nil )
      super(context, name)
      
      if id_name && id_table then
         @id_field = add_field(schema.adapter.reference_field_class.new(self, id_name, id_table, false, true))
      else
         @id_field = add_field(schema.adapter.identifier_field_class.new(self, id_name || (context.responds_to?(:id_field) ? context.id_field : "id"), nil))
      end
      
      context.define_owner_fields(self)
   end
   
   attr_reader :id_field
   alias :fields :children
   
   def []( *names )
      return self[names] unless names.length == 1
      
      names = names.first
      case names
      when "*"
         @children.members
      when Hash
         @children.select{|field| names.member?(field.name)}
      when Array
         [].tap do |fields|
            @children.each do |name, field|
               fields << field if names.member?(field.name)
            end
         end
      else
         [@children[names]]
      end
   end
   
   def add_field( field )
      add_child field
   end
   
   def define_table( name, id_name = nil, id_table = nil )
      @context.define_table(make_name(name.to_s, @name.to_s), id_name || "id", id_table)
   end

   def define_owner_fields( into )
      into.add_field schema.adapter.reference_field_class.new(into, :__owner, self, false, true)
   end
   
   
   def to_sql_create( if_not_exists = true )
      keys = ["primary key (#{quote_identifier(@id_field.name)})"]
      body = @children.collect{|c| c.to_sql_create()}.join(",\n   ") + (keys.empty? ? "" : ",") + "\n\n   " + keys.join(",\n   ")
      
      "CREATE TABLE #{sql_name}\n(\n   #{body}\n);"
   end
   
   def to_sql_select( field_names = "*", restrictions = {} )      
      fields = self[field_names] 
      where  = ""
      if restrictions === false then
         where = " WHERE 1 = 0"
      else !restrictions.empty?
         pairs = self[restrictions].collect{|field| field.to_sql_comparison(restrictions[field.name])}
         where = " WHERE #{pairs.join(" and ")}"
      end

      "SELECT #{fields.collect{|f| f.sql_name}.join(", ")} FROM #{sql_name}#{where}"
   end
   
   def to_sql_existence_check()
      "SELECT 1 FROM #{sql_name}"
   end

   def to_sql_insert( values = {} )      
      fields = self[values]
      quoted_values = fields.collect{|f| f.sql_value(values[f.name])}
      "INSERT INTO #{sql_name} (#{fields.collect{|f| f.sql_name}.join(", ")}) VALUES (#{quoted_values.join(", ")})"
   end

   def to_sql_update( values = {}, restrictions = {} )
      value_fields       = self[values]
      restriction_fields = self[restrictions]
      field_sets         = value_fields.collect{|f| f.to_sql_assignment(values[f.name])}
      restriction_pairs  = restriction_fields.collect{|field| field.to_sql_comparison(restrictions[field.name])}
      where_clause       = restriction_pairs.empty? ? "" : " WHERE #{restriction_pairs.join(" and ")}"
      
      "UPDATE #{sql_name} SET #{field_sets.join(", ")}#{where_clause}"
   end
   
   
end # Table
end # Generic
end # Adapters
end # Schemaform
