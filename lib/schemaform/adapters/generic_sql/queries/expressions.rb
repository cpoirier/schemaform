#!/usr/bin/env ruby -KU
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


#
# Base class for any SQL relation.

module Schemaform
module Adapters
module GenericSQL
module Queries
   
   Comparison = PrintableStruct.define(:operator, :lhs, :rhs)
   Field      = PrintableStruct.define(:name                )
   Parameter  = PrintableStruct.define(:number              )


   class And
      def initialize( *clauses )
         @clauses = []
         clauses.flatten.each do |clause|
            if clause.is_an?(And) then
               @clauses.concat(clause.clauses)
            else
               @clauses << clause
            end
         end
      end

      attr_reader :clauses
      
      def print_to( printer )
         printer.label(self.class.unqualified_name) do
            @clauses.each do |clause|
               clause.print_to(printer)
            end
         end
      end
   end

   class Or < And ; end

end # Queries
end # GenericSQL
end # Adapters
end # Schemaform
