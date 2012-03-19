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

require Schemaform.locate("boolean_expression.rb")


#
# Base class for things that help make up a Query.

module Schemaform
module Adapters
module GenericSQL
module QueryParts
class Not < BooleanExpression

   def initialize( type_info, expression )
      super(type_info)
      @expression = expression
   end
   
   attr_reader :expression
   
   def print_to( printer )
      printer << "NOT "
      @expression.print_to(printer)
   end

end # Not
end # QueryParts
end # GenericSQL
end # Adapters
end # Schemaform