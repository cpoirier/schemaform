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
module GenericSQL
class Adapter
   
   
   #
   # Plans a query for use with this database.
   
   def plan_query( definition )
      unless @query_plans.member?(definition)
         
         #
         # Plan the query without tying up the environment, but make sure what we actually 
         # store only the first plan, so that resources can be tied to the object.
         
         sources    = {}
         query_plan = query_plan(definition, )
         @monitor.synchronize do
            unless @query_plans.member?(definition)
               @query_plans[definition] = query_plan
            end
         end
      end
      
      @query_plans[definition]
   end
   
   def query_plan( object )
      case object
      when Language::Placeholder
         dispatch(:query_plan, object.get_production)
      when Language::Production
         dispatch(:query_plan, object)
      else
         fail "#{object.class.name} not supported"
      end
   end

   def query_plan_restriction( restriction )
      QueryPlan::Restriction.new(query_plan(restriction.criteria))
   end

   def query_plan_and( production )
      QueryPlan::And.new(*production.clauses.collect{|c| query_plan(c)})
   end
   
   def query_plan_or( production )
      QueryPlan::Or.new(*production.clauses.collect{|c| query_plan(c)})
   end

   def query_plan_comparison( production )
      case production.operator
      when :==
         QueryPlan::IsEqual.new(query_plan(production.lhs), query_plan(production.rhs))
      else
         fail_todo production.operator
      end
   end
   
   def query_plan_value_accessor( production )
      QueryPlan::Value.new(query_plan(production.attribute))
   end
   
   def analyze_predicate_accessor( production )
      QueryPlan::Attribute.new(query_plan(production.receiver.get_production), production.symbol)
   end
   
   def query_plan_each_tuple( production )
      map_query_source(production.relation)
   end
   
   
   
   
   
   




end # Adapter
end # GenericSQL
end # Adapters
end # Schemaform
