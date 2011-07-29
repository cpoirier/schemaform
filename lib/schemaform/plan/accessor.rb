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
# Describes an accessor on an Entity, which should translate to an entry point at runtime. 

module Schemaform
module Plan
class Accessor
   
   def self.build_key_accessor( entity_plan, key )
      query = entity_plan.entity.entity_context.where do |entity|
         Language::ExpressionCapture.resolution_scope(entity_plan.entity.schema) do 
            comparisons = []
            key.attributes.each_with_index do |attribute, index|
               comparisons << (entity[attribute.name] == parameter!(index))
            end

            and!(*comparisons)
         end
      end
   
      new( entity_plan, key, query )
   end

   def initialize( entity_plan, key, query )
      @entity_plan = entity_plan
      @key         = key
      @query       = query      
   end
   
   attr_reader :query

end # Accessor
end # Plan
end # Schemaform