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
# An Expression wrapper on a Tuple Definition.

module Schemaform
module Expressions
class DefinedTuple

   def initialize( definition )
      @definition = definition
   end
   
      
   def method_missing( symbol, *args, &block )
      tuple = @definition.resolve()
      if tuple.member?(symbol) then
         return DottedExpression.new(self, symbol, tuple.attributes[symbol].resolve())
      end
   
      
      # x.y
      # 
      # x type            | y possibilities
      # ======================================================================
      # tuple             | attribute of the tuple
      # list_of(tuple)    | .first, .last, .value (the array of tuples), direct column attributes (convenience, where no conflict)
      # list_of(scalar)   | .first, .last, .value is the column
      # set_of(tuple)     | direct column attributes
      # set_of(scalar)    | there is no y, unless scalar is a reference, in which case it's an aggregate tuple attribute
      # member_of(entity) | y is an atturibute of the tuple

   end
      

end # DefinedTuple
end # Expressions
end # Schemaform