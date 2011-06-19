#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2010 Chris Poirier
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

   def initialize( context, name, id_name = nil )
      super(context, name)
      @id_field = add_field(IdentifierField.new(self, id_name || context.id_field, nil))
      context.define_owner_fields(self)
   end
   
   attr_reader :id_field
   alias :fields :children
   
   def add_field( field )
      add_child field
   end
   
   def define_table( name, id_name = nil )
      qualified_name = @name.to_s + "__" + name.to_s
      @context.define_table(qualified_name, id_name || "id")
   end

   def define_owner_fields( into )
      into.add_field ReferenceField.new(into, :__owner, self, false, true)
   end
   
   def to_sql( name_prefix = nil )
      fields = @children.collect{|c| c.to_sql()}.join(",\n   ")
      "create table #{name_prefix}#{@name}\n(\n   #{fields}\n)"
   end

end # Table
end # Generic
end # Adapters
end # Schemaform
