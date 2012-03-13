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
         query_plan = plan_query_structure(definition)
         @monitor.synchronize do
            unless @query_plans.member?(definition)
               @query_plans[definition] = query_plan
            end
         end
      end
      
      @query_plans[definition].tap do |query_plan|
         # Printer.print(render_sql_query(query_plan))
      end
   end
   
   def plan_query_structure( object, naming_context = nil )
      naming_context ||= NamingContext.new(self)
      
      case object
      when Language::Production
         dispatch(:plan, object, naming_context)
      when Language::Entity
         Queries::Entity.new(map_entity(object.get_definition), naming_context.current)
      when Language::Parameter
         Queries::Parameter.new(object.get_number)
      when Language::Placeholder
         dispatch(:plan, object.get_production, naming_context)
      else
         fail "#{object.class.name} not supported"
      end
   end
   
   alias plan_query_expression plan_query_structure
   

   def plan_restriction( restriction, naming_context )
      source   = plan_query_structure(restriction.relation)
      criteria = plan_query_expression(restriction.criteria)
      
      Queries::Restriction.new(source, criteria)
   end



   def plan_comparison( comparison, naming_context )
      lhs = plan_query_expression(comparison.lhs)
      rhs = plan_query_expression(comparison.rhs)
      
      Queries::Comparison.new(comparison.operator, lhs, rhs)
   end
   
   
   def plan_value_accessor( production, naming_context )
      Queries::Field.new(naming_context.current + production.attribute.get_production.symbol.to_s)
   end
   
   def plan_and( production, naming_context )
      Queries::And.new(production.clauses.collect{|clause| plan_query_expression(clause, naming_context)})
   end

   def plan_or( production, naming_context )
      Queries::Or.new(production.clauses.collect{|clause| plan_query_expression(clause, naming_context)})
   end


   # select member_id, email, display_name, created, profile_name, profile, authentication, wfg, following
   # from random_members r1
   # where created = ?
   
   
   
   


   


   class NamingContext
      attr_reader :current
      def initialize( adapter ) ; @current = adapter.empty_name() ; end
      def enter( name ) 
         old = @current
         begin
            @current = @current + name
         ensure
            @current = old
         end
      end
   end

end # Adapter
end # GenericSQL
end # Adapters
end # Schemaform

