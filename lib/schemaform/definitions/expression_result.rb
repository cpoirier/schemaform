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

#
# Represents a Definition within a running Expression. Note that ExpressionResults are produced 
# on demand at the result of each subexpression -- they carry with them the expression that 
# produced them.

module Schemaform
module Definitions
class ExpressionResult
   include QualityAssurance

   def initialize( definition, production = nil )
      @definition = definition
      @production = production
   end
   
   attr_reader :definition, :production

   def type()
      @definition.type
   end
   
   def *( rhs )
      result_type = self.type.best_common_type(rhs.type)
      Variable.new(result_type, BinaryOperator.new(:*, self, rhs))
   end
   
end # ExpressionResult
end # Definitions
end # Schemaform

