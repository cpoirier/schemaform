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
# Represents an Entity within a Transaction.

module Schemaform
module Runtime
class ConnectedEntity
   include QualityAssurance
   extend  QualityAssurance

   def initialize( transaction, definition )
      @transaction = transaction
      @definition  = definition
      @plan        = definition.plan
      @mappings    = {}
   end
   
   def method_missing( symbol, *args, &block )
      if @mappings.member?(symbol) then
         fail_todo
      elsif @plan.operations.member?(symbol) then
         return @plan.operations[symbol].call(@transaction, *args, &block)
      else
         case name = symbol.to_s
         when /^get_(\w+)_by_(\w+)$/
            projection_name = $1
            accessor_name   = $2

            fail_todo
            
            if @plan.projections.member?(projection_name) && @plan.accessors.member?(accessor_name) then
               accessor = @plan.accessors[accessor_name].projection(projection_name)
            end
         
         when /^get_by_(\w+)$/
            accessor_name = $1
            if @plan.accessors.member?(accessor_name) then
               accessor_plan = @plan.accessors[accessor_name]
               return @transaction.retrieve(accessor_plan.query)
            end
         end
      end
      
      super
   end

end # ConnectedEntity
end # Runtime
end # Schemaform

