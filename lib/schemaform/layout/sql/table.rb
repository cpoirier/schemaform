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
module Layout
module SQL
class Table < Component

   def initialize( context, name, id_name = nil )
      super(context, name)
      @id_field = define_field(id_name || :__id, schema.identifier_type)
      context.define_owner_fields(self)
   end
   
   attr_reader :id_field
   alias :fields :children
   
   def define_field( name, type, references_field = nil )
      add_child Field.new(self, name, type, references_field)
   end

   def define_owner_fields( into )
      into.define_field(:__parent_id, schema.identifier_type, @id_field)
   end

end # Table
end # SQL
end # Layout
end # Schemaform
