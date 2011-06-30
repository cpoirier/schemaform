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
         @id_field = add_field(schema.driver.reference_field_class.new(self, id_name, id_table, false, true))
      else
         @id_field = add_field(schema.driver.identifier_field_class.new(self, id_name || context.id_field, nil))
      end
      
      context.define_owner_fields(self)
   end
   
   attr_reader :id_field
   alias :fields :children
   
   def add_field( field )
      add_child field
   end
   
   def define_table( name, id_name = nil, id_table = nil )
      @context.define_table(make_name(name.to_s, @name.to_s), id_name || "id", id_table)
   end

   def define_owner_fields( into )
      into.add_field schema.driver.reference_field_class.new(into, :__owner, self, false, true)
   end
   
   def to_create_sql( name_prefix = nil )
      fields = @children.collect{|c| c.to_create_sql()}
      keys   = ["primary key (#{quote_identifier(@id_field.name)})"]
      body   = fields.join(",\n   ") + (keys.empty? ? "" : ",") + "\n\n   " + keys.join(",\n   ")
      
      "create table #{name_prefix}#{@name}\n(\n   #{body}\n);"
   end

end # Table
end # Generic
end # Adapters
end # Schemaform
