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

require Schemaform.locate("query.rb")


#
# A projection (with possible renaming) of attributes.

module Schemaform
module Adapters
module GenericSQL
module Queries
class Projection < Query

   def initialize( source, mappings = {} )
      super(source.adapter)
      
      @source   = source
      @mappings = mappings
      @fields   = Registry.new()

      @source.fields.each do |name, type|
         if mappings.member?(name) then
            @fields.register(name, mappings[name])  # name is the value, mappings[name] (the new name) is the key
         end
      end
   end
   
   attr_reader :source, :mappings, :fields
   
end # Projection
end # Queries
end # GenericSQL
end # Adapters
end # Schemaform
