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
module GenericSQL
class QueryPlan   
   include QualityAssurance
   
   def initialize( adapter )
      @adapter = adapter
      @steps   = [RetrievalStep.new()]
      
      # @join_plan      = JoinPlan.new()
      # @predicate_plan = PredicatePlan.new()
   end
   
   def enter_predicate_and()
      yield
   end
   
   def enter_predicate_or()
      yield
   end
   
   def enter_predicate_comparison( operator )
      
      yield
   end
   
   def enter_predicate_comparison_lhs()
      yield
   end
   
   def enter_predicate_comparison_rhs()
      yield
   end
   
   def enter_value_accessor()
      yield
   end
   
   def connect( source, name )
      # if source.is_an?(Schema::Entity) then
      # else
      #    
      p source.class.name
      fail_todo
   end 


end # QueryPlan
end # GenericSQL
end # Adapters
end # Schemaform