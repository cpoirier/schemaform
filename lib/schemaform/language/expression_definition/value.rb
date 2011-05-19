#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2010 Chris Poirier
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

require Schemaform.locate("base.rb")

#
# Base class for values.

module Schemaform
module Language
module ExpressionDefinition
class Value < Base

   def initialize( type, production = nil )
      super(type)
      @production = production
   end
   
   def production!()
      @production
   end
   
   def +( rhs )
      rhs = markup!(rhs)
      
      result_type = self.type!.best_common_type(rhs.type!)
      result_type.marker(Productions::BinaryOperator.new(:+, self, rhs))
   end
   
   def *( rhs )
      rhs = markup!(rhs)

      result_type = self.type!.best_common_type(rhs.type!)
      result_type.marker(Productions::BinaryOperator.new(:*, self, rhs))
   end
   
   def method_missing( symbol, *args, &block )
      if result_type = @type.method_type(symbol, *args, &block) then
         Value.new(result_type, Productions::MethodCall.new(self, symbol, *args, &block))
      else
         super
      end
   end
   

end # Value
end # ExpressionDefinition
end # Language
end # Schemaform

