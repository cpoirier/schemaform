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
# Adds query planning code to the Adapter.

module Schemaform
module Adapters
module Generic
class Adapter
   
   
   #
   # Plans a query for use with this database.
   
   def plan( definition )
      unless @query_plans.member?(definition)
         
         #
         # Plan the query without tying up the environment, but make sure what we actually 
         # store is unique, so that resources can be tied to the object.
         
         query_plan = dispatch_plan(definition, QueryPlan.new())
         @monitor.synchronize do
            unless @query_plans.member?(definition)
               query_plans[definition] = query_plan
            end
         end
      end
      
      @query_plans[definition]
   end

   def dispatch_plan( definition, plan )
      send_specialized(:plan, definition, plan)
   end



end # Adapter
end # Generic
end # Adapters
end # Schemaform
