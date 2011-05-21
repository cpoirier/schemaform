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
# Provides access to a Entity-examplar Tuple and its attributes. This is the Marker passed
# to the Formula for a derived attribute.

module Schemaform
module Language
module ExpressionDefinition
class Tuple < Base

   def initialize( tuple, production = nil )
      super()
      @production = production
      @tuple      = tuple
   end
   
   def type()
      @tuple.type
   end
   
   def if_then_else( condition, true_branch, false_branch = nil )
      condition    = Base.markup(condition   )
      true_branch  = Base.markup(true_branch )
      false_branch = Base.markup(false_branch)
      
      # assert(condition.type.boolean_type, "the if_then_else condition must have a boolean type")
      
      production = Productions::IfThenElse.new(condition, true_branch, false_branch)
      Base.merge_types(true_branch, false_branch).marker(production)
   end
   
   def method_missing( symbol, *args, &block )
      attribute = Base.lookup(@tuple.attributes, symbol, args, block) or return super
      attribute.marker(Productions::Accessor.new(self, symbol))
   end
   

end # Tuple
end # ExpressionDefinition
end # Language
end # Schemaform
