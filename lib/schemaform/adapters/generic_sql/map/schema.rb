#!/usr/bin/env ruby
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

require Schemaform.locate("node.rb")


#
# Imports the Model::Schema into the adapter for processing.

module Schemaform
module Adapters
module GenericSQL
module Map
class Schema < Node

   def initialize( adapter, model )
      super
      
      @entity_maps = {}      
      model.entities.each do |entity|
         @entity_maps[entity.name] = adapter.map(entity)
      end
   end
   

end # Schema
end # Map
end # GenericSQL
end # Adapters
end # Schemaform