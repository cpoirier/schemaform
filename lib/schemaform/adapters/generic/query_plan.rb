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
# Holds a complete plan for executing a Schemaform query, and provides the machinery to do so.

module Schemaform
module Adapters
module Generic
class QueryPlan

   def initialize()
      @entity_aliases  = {}
      @used_attributes
   end
   
   
   def entity_alias( placeholder )
      @entity_aliases[placeholder.object_id] ||= "e#{@entity_aliases.length + 1}"
   end
   
   def use_field

end # QueryPlan
end # Generic
end # Adapters
end # Schemaform