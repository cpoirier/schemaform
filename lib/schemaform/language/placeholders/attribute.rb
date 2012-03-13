#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
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


#
# Provides access to a Tuple and its attributes.

module Schemaform
module Language
class Attribute < Placeholder

   def initialize( definition, production = nil )
      super(definition.type, production)
      @definition = definition
      @effective  = definition.type.placeholder(Productions::ValueAccessor.new(self))
   end
   
   def get_definition() ; @definition ; end
   def get_effective()  ; @effective  ; end
   
   def method_missing( symbol, *args, &block )
      @effective.send(symbol, *args, &block)
   end
   
   def ==( rhs )
      @effective.send(:==, rhs)
   end
   
   #
   # Builds an expression that branches based on whether or not a value has been stored in the
   # attribute (default values will be present otherwise).

   def present?( true_value = nil, false_value = nil )
      true_value  = FormulaCapture.capture(true_value )
      false_value = FormulaCapture.capture(false_value)      
      result_type = true_value ? FormulaCapture.merge_types(true_value.get_type, false_value.get_type) : FormulaCapture.resolve_type(:boolean)

      result_type.placeholder(Productions::PresentCheck.new(self, true_value, false_value))
   end
   
   
   #
   # Builds an expression that returns the value of the attribute. The system infers
   # when this should be applied, so you probably won't ever need to call it directly.
   #
   # Note: this method should naturally be called "value", but that word is too likely
   # to be used as an attribute name in a tuple, causing an odd, hard-to-find bug, so
   # evaluate() it is.
   
   def evaluate()
      @effective
   end
   

   
   
end # Attribute
end # Language
end # Schemaform

