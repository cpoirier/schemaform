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
   
   def self.build( schemas )
      environment = Environment.build(self, template_name)
      available_schemas.each do |schema|
         
      end
   end
   
   
   #    #
   #    # If we did the association, lay out the schema for use and ensure the physical schema is 
   #    # up-to-date. Finally, register the names for lookup.
   #    
   #    if associated then
   #       schema.upgrade(self, @associated_schemas[schema])
   #       
   #       @monitor.synchronize do
   #          @by_schema_version_entity[schema.name] = {} unless @by_schema_version_entity.member?(schema.name)
   #          @by_schema_version_entity[schema.name][schema.version] = schema unless @by_schema_version_entity[schema.name].member?(schema.version)
   #          
   #          @by_schema_entity[schema.name] = schema unless @by_schema_entity.member?(schema.name)
   #       
   #          schema.entities.each do |entity|
   #             @by_entity[entity.name] = entity unless @by_entity.member?(entity.name)
   #          end
   #       end
   #    end
   # end
   # 
   # 
   # #
   # # Returns the Schema::Entity for the specified name vector:
   # #    * entity_name
   # #    * schema_name, entity_name
   # #    * schema_name, schema_version, entity_name
   # 
   # def []( *address )
   #    case address.length
   #    when 1
   #       @by_entity[address.shift]
   #    when 2
   #       @by_schema_entity[address.shift][address.shift]
   #    when 3
   #       @by_schema_version_entity[address.shift][address.shift][address.shift]
   #    else
   #       fail
   #    end
   # end
   


protected

   def initialize()
      
   end
   
end # Workspace
end # Runtime
end # Schemaform