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
# Anchors a set of tables to the source Schema definition.

module Schemaform
module Adapters
module Generic
class Schema
   include QualityAssurance
   extend  QualityAssurance

   def initialize( name, adapter )
      @name               = name
      @adapter            = adapter
      @tables             = Registry.new()
      @entity_tables      = {}              # Schema::Entity    => Table
      @attribute_mappings = {}              # Schema::Attribute => Mapping 
   end
   
   attr_reader :adapter, :tables, :entity_tables, :attribute_mappings
      
   def define_master_table( name, id_name = nil, base_table = nil )
      register @adapter.table_class.build_master_table(self, name, id_name, base_table)
   end
   
   def define_child_table( parent_table, name )
      register @adapter.table_class.build_child_table(self, parent_table, name)
   end
   
   def register( table )
      @tables.register(table)
   end
      
   def map_attribute( attribute, mapping )
      @attribute_mappings[attribute] = mapping
   end
   
   def to_sql_create()
      @adapter.render_sql_create(self)
   end
   

end # Schema
end # Generic
end # Adapters
end # Schemaform
