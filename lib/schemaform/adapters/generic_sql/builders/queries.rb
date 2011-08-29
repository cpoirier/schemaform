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
   
   def plan( definition )
      unless @query_plans.member?(definition)
         
         #
         # Plan the query without tying up the environment, but make sure what we actually 
         # store only the first plan, so that resources can be tied to the object.
         
         query_plan = dispatch_planner(definition, QueryPlan.new(self))
         @monitor.synchronize do
            unless @query_plans.member?(definition)
               @query_plans[definition] = query_plan
            end
         end
      end
      
      @query_plans[definition]
   end


   def dispatch_planner( definition, query_plan )
      send_specialized(:plan, definition, query_plan)
   end


   def plan_placeholder( placeholder, query_plan )
      placeholder.get_production ? dispatch_planner(placeholder.get_production, query_plan) : nil
   end
   
   
   def plan_restriction( restriction, query_plan )
      # relation, criteria


      Printer.dump(restriction)
      analyze_predicate(restriction.criteria, query_plan)
      fail_todo
   end









   def analyze_predicate( clause, query_plan )
      clause = clause.get_production if clause.is_a?(Language::Placeholder)
      send_specialized(:analyze_predicate, clause, query_plan)
   end
   
   def analyze_predicate_and( production, query_plan )
      query_plan.enter_predicate_and do
         production.clauses.each do |clause|
            analyze_predicate(clause, query_plan)
         end
      end
   end
   
   def analyze_predicate_or( production, query_plan )
      query_plan.enter_predicate_or do
         production.clauses.each do |clause|
            dispatch_predicate_analyzer(clause, query_plan)
         end
      end
   end

   def analyze_predicate_comparison( production, query_plan )
      query_plan.enter_predicate_comparison(production.operator) do
         query_plan.enter_predicate_comparison_lhs{analyze_predicate(production.lhs, query_plan)}
         query_plan.enter_predicate_comparison_rhs{analyze_predicate(production.lhs, query_plan)}
      end
   end
   
   def analyze_predicate_value_accessor( production, query_plan )
      query_plan.enter_value_accessor{analyze_predicate(production.attribute, query_plan)}
   end
   
   def analyze_predicate_accessor( production, query_plan )
      each_tuple = production.receiver.get_production
      type_check(:each_tuple, each_tuple, Language::Productions::EachTuple)
      query_plan.connect(each_tuple.relation, production.symbol)
   end
   
   
   
   
   
   




end # Adapter
end # GenericSQL
end # Adapters
end # Schemaform
