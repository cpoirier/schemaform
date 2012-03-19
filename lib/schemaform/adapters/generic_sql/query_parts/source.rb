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

require Schemaform.locate("part.rb")


#
# Base class for things that help make up a Query.

module Schemaform
module Adapters
module GenericSQL
module QueryParts
class Source < Part

   def initialize( query, op, relation )
      @query    = query
      @op       = op
      @relation = relation
      @alias    = nil
   end
   
   attr_accessor :alias
   
   def fields()
      @relation.fields
   end
   
   def adapter()
      @query.adapter
   end
   
   def print_to( printer )
      printer << "#{@op} "
      
      case @relation
      when Query
         printer.end_line
         printer << "(\n"
         printer.indent { printer.print @relation.to_s }
         printer << ") #{@alias}"
      when Table
         printer << "#{@relation.quoted_name} #{@alias}"
      else 
         fail
      end
   end

end # Source
end # QueryParts
end # GenericSQL
end # Adapters
end # Schemaform