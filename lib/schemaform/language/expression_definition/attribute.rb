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
# Provides access to a Tuple and its attributes.

module Schemaform
module Language
module ExpressionDefinition
class Attribute < Base

   def initialize( definition, production = nil )
      super()
      @production = production
      @definition = definition
      @effective  = definition.type.marker(Productions::ImpliedContext.new(self))
   end
   
   def type()
      @definition.type
   end
   
   def method_missing( symbol, *args, &block )
      @effective.send(symbol, *args, &block)
   end
   
   #
   # Builds an expression that branches based on whether or not a value has been stored in the
   # attribute (default values will be present otherwise).

   def present?( true_value = nil, false_value = nil )
      true_value  = Base.markup(true_value )
      false_value = Base.markup(false_value)      
      result_type = true_value ? Base.merge_types(true_value, false_value) : Base.type(:boolean)

      result_type.marker(Productions::PresentCheck.new(self, true_value, false_value))
   end

   
   
end # Attribute
end # ExpressionDefinition
end # Language
end # Schemaform

