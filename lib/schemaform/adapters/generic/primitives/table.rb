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
# A table, possibly nested, (for naming purposes only). 

module Schemaform
module Adapters
module Generic
class Table
   include QualityAssurance
   extend  QualityAssurance
   
   def self.build_master_table( schema, name, id_name = nil, base_table = nil )
      name = Name.build(name)
      schema.adapter.table_class.new(schema, name).tap do |table|
         modifier = base_table ? ReferenceMark.build(base_table) : GeneratedMark.build()
         table.identifier = table.define_field(id_name || Name.build("id", name.last), schema.adapter.type_manager.identifier_type, modifier, PrimaryKeyMark.build())
      end
   end
   
   def self.build_child_table( schema, parent_table, name, has_many = true )
      schema.adapter.table_class.new(schema, parent_table.name + name).tap do |table|
         table.owner = table.define_field(Name.build("owner", parent_table.identifier.name), schema.adapter.type_manager.identifier_type, ReferenceMark.build(parent_table))

         if has_many then
            table.identifier = table.define_field(Name.build("table", "id"), schema.adapter.type_manager.identifier_type, GeneratedMark.build(), PrimaryKeyMark.build())
         else
            table.owner.marks << PrimaryKeyMark.build()
            table.identifier = table.owner
         end
      end
   end
   
   attr_reader   :schema, :name, :fields
   attr_accessor :identifier, :owner
   
   def adapter()
      @schema.adapter
   end

   def define_field( name, type, *modifiers )
      @fields.register(adapter.field_class.new(self, name, type, *modifiers))
   end

   def define_child(name)
      @schema.define_child_table(self, name)
   end
   
   def attribute_mappings()
      @schema.attribute_mappings
   end
   

   def install( connection )
      unless present?(connection)
         connection.execute(@schema.adapter.render_sql_create(self))
      end
   end
   
   
   def to_sql_create()
      @schema.adapter.render_sql_create(self)
   end


protected

   def initialize( schema, name )
      type_check(:schema, schema, Generic::Schema)
      @schema  = schema
      @name    = name
      @fields  = Registry.new(name.to_s, "a field")
   end


   def present?( connection )
      begin
         connection.retrieve("SELECT * FROM #{@name} WHERE 1 = 0")
         return true
      rescue Error => e
         return false
      end
   end



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
   
   
   
   
end # Table
end # Generic
end # Adapters
end # Schemaform


Dir[Schemaform.locate("field_marks/*.rb")].each{|path| require path}
