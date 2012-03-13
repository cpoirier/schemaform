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

require Schemaform.locate("query.rb")


#
# A single query (or subquery).

module Schemaform
module Adapters
module GenericSQL
module Queries
class Restriction < Query

   def initialize( source, criteria )
      super(source.adapter)
      
      if source.is_a?(Restriction) then
         @source   = source.source
         @criteria = And.new(source.criteria, criteria)
      else
         @source   = source
         @criteria = criteria
      end
   end
   
   attr_reader :source, :criteria
   
   def fields()
      @source.fields
   end
   
end # Restriction
end # Queries
end # GenericSQL
end # Adapters
end # Schemaform
