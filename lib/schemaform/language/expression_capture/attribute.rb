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

require Schemaform.locate("value.rb")


#
# Provides access to a Tuple and its attributes.

module Schemaform
module Language
module ExpressionCapture
class Attribute < Value

   def initialize( definition, production = nil )
      super(definition.type, production)
      @definition = definition
      @effective  = definition.type.capture(Productions::ImpliedContext.new(self))
   end
   
   def method_missing( symbol, *args, &block )
      @effective.send(symbol, *args, &block)
   end
   
   #
   # Builds an expression that branches based on whether or not a value has been stored in the
   # attribute (default values will be present otherwise).

   def present?( true_value = nil, false_value = nil )
      true_value  = ExpressionCapture.capture(true_value )
      false_value = ExpressionCapture.capture(false_value)      
      result_type = true_value ? ExpressionCapture.merge_types(true_value, false_value) : ExpressionCapture.resolve_type(:boolean)

      result_type.capture(Productions::PresentCheck.new(self, true_value, false_value))
   end

   
   
end # Attribute
end # ExpressionCapture
end # Language
end # Schemaform

