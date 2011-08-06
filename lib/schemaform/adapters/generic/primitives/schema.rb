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
      @name        = name
      @adapter     = adapter
      @tables      = Registry.new()
      @entity_maps = {}       # Schema::Entity    => EntityMap
   end
   
   attr_reader :adapter, :tables, :entity_maps, :attribute_mappings
      
   def define_table( name )
      @adapter.table_class.new(self, name).tap do |table|
         register(table)
         yield(table) if block_given?
      end   
   end
   
   def register( table )
      @tables.register(table)
   end

   def map_entity( entity, anchor_table )
      @entity_maps[entity] = EntityMap.new(entity, anchor_table, @entity_maps[entity.base_entity])
   end
   
   def to_sql_create()
      @adapter.render_sql_create(self)
   end
   

end # Schema
end # Generic
end # Adapters
end # Schemaform
