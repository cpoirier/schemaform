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

require Schemaform.locate("expression.rb")


#
# Base class for things that help make up a Query.

module Schemaform
module Adapters
module GenericSQL
module QueryParts
class Comparison < BooleanExpression

   def initialize( type_info, op, lhs, rhs )
      super(type_info)
      @op  = op
      @lhs = lhs
      @rhs = rhs
      
      #
      # We will simplify production of field reference to literal comparisons by making sure the
      # field reference is always on the LHS. We invert the op if we switch.
      
      if @lhs.is_a?(Literal) && !@rhs.is_a?(Literal) then
         @lhs, @rhs = @rhs, @lhs
         @op = invert_op(@op)
      end
   end
   
   attr_reader :op, :lhs, :rhs
   
   def print_to( printer )
      if @lhs.is_a?(Literal) && @rhs.is_a?(Literal) then
         if @lhs.value.nil? || @rhs.value.nil? then
            printer << "null"
            return
         end
      end
            
      @lhs.print_to(printer)
      if @rhs.is_a?(Literal) then
         printer << @rhs.type_info.op_literal(@op, @rhs.value)
      else
         printer << " #{@op} "
         @rhs.print_to(printer)
      end
   end
   
   def invert_op( op )
      case op
      when ">=" ; "<"
      when "<=" ; ">"
      when ">"  ; "<="
      when "<"  ; ">="
      else op
      end
   end

end # Comparison
end # QueryParts
end # GenericSQL
end # Adapters
end # Schemaform
