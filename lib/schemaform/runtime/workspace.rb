#!/usr/bin/env ruby -KU
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


#
# Captures a set of schemas for use as a single runtime environment.

module Schemaform
module Runtime
class Workspace

   #
   # Figures out a name for the specified list of schemas.
   
   def self.name( schemas )
      schemas.collect{|s| s.schema_id}.join("|")
   end
   
   
   #
   # Builds a Workspace from a list of Schemas.
   
   def initialize( database, schemas )
      @name           = self.class.name(schemas)
      @database       = database
      @version_lookup = {}
      @schema_lookup  = {}
      @entity_lookup  = {}

      schemas.each do |schema|
         @version_lookup[schema.name] = {} unless @version_lookup.member?(schema.name)
         @version_lookup[schema.name][schema.version] = schema unless @version_lookup[schema.name].member?(schema.version)
         
         @schema_lookup[schema.name] = schema unless @schema_lookup.member?(schema.name)
         
         schema.entities.each do |entity|
            @entity_lookup[entity.name] = entity unless @entity_lookup.member?(entity.name)
         end
      end      
   end
   
   attr_reader :database
      
   
   #
   # Returns the Schema::Entity for the specified name vector:
   #    * entity_name
   #    * schema_name, entity_name
   #    * schema_name, schema_version, entity_name
   
   def []( *address )
      entity = case address.length
      when 1         
         case address.first
         when Schema::Entity
            entity = address.shift
            @version_lookup.fetch(entity.schema.version).fetch(entity.schema.name).fetch(entity.name)
         else
            @entity_lookup.fetch(address.shift)
         end
      when 2
         @schema_lookup.fetch(address.shift).fetch(address.shift)
      when 3
         @version_lookup.fetch(address.shift).fetch(address.shift).fetch(address.shift)
      else
         fail
      end
   end
   
end # Workspace
end # Runtime
end # Schemaform
