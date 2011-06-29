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
# Anchors a set of tables to the source Schema definition.

module Schemaform
module Adapters
module Generic
class Schema < Component

   def initialize( definition )
      super(nil, definition.name)
      @definition = definition
   end
   
   attr_reader :definition
   alias :tables :children
   
   def define_table( name, id_name = nil, id_table = nil )
      add_child Table.new(self, name, id_name, id_table)
   end

   def define_owner_fields( into )      
   end
   
   def identifier_type()
      @definition.identifier_type
   end
   
   def to_sql( name_prefix = nil )
      table_sql = @children.collect do |table|
         table.to_sql(name_prefix)
      end
      
      table_sql.join("\n\n")
   end
   

end # Schema
end # Generic
end # Adapters
end # Schemaform
