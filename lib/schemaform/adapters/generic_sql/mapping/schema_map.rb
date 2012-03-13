#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
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


#
# Captures information about how a Schema is mapped into Tables and Fields.

module Schemaform
module Adapters
module GenericSQL
class SchemaMap

   def initialize( adapter, definition )
      @adapter     = adapter
      @definition  = definition
      @entity_maps = {}
      @tables      = []
   end
   
   attr_reader :adapter, :definition, :entity_maps, :tables
   
   def []( entity_definition )
      @entity_maps[entity_definition]
   end
   
   def map( definition, anchor_table )
      @adapter.entity_maps[definition] = @entity_maps[definition] = EntityMap.new(self, definition, anchor_table)
      yield(@entity_maps[definition], anchor_table) if block_given?
   end
   
   def register_table( table )
      @tables << table
   end
 
end # SchemaMap
end # GenericSQL
end # Adapters
end # Schemaform

