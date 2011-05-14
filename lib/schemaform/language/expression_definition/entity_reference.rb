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

require Schemaform.locate("marker.rb")
require Schemaform.locate("schemaform/expressions/accessor.rb")


#
# Provides access to a Tuple and its attributes.

module Schemaform
module Language
module ExpressionDefinition
class EntityReference < Marker

   def initialize( reference_type, production = nil )
      super(production)
      @reference_type = reference_type
      @tuple = reference_type.referenced_entity.heading
   end
   
   def method_missing( symbol, *args, &block )
      return super unless @tuple.member?(symbol)
      @tuple[symbol].marker(Expressions::Accessor.new(self, symbol))
   end
   
end # Attribute
end # ExpressionDefinition
end # Language
end # Schemaform

