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

require Schemaform.locate("attribute.rb")


#
# Provides access to a Tuple and its attributes.

module Schemaform
module Language
module ExpressionDefinition
class OptionalAttribute < Attribute

   def initialize( definition, production = nil )
      super(definition, production)
   end
   
   def method_missing( symbol, *args, &block )
      handler = @definition.definition.marker(Expressions::ImpliedContext.new(self))
      handler.send(symbol, *args, &block)
   end
   
   
   #
   # Builds an expression that branches based on whether or not a value has been stored in the
   # attribute (default values will be present otherwise).

   def present?( true_value, false_value = nil )
      true_value  = markup!(true_value )
      false_value = markup!(false_value)
      
      result_type = true_value.type
      result_type = result_type.best_common_type(false_value.type) if false_value

      result_type.marker(Expressions::PresentCheck.new(self, true_value, false_value))
   end

end # OptionalAttribute
end # ExpressionDefinition
end # Language
end # Schemaform
