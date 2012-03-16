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

require Schemaform.locate("scalar_type.rb" )
require Schemaform.locate("integer_type.rb")
require Schemaform.locate("string_type.rb" )


#
# Base class for enumerated types.

module Schemaform
class Schema
class EnumeratedType < ScalarType

   def initialize( values, attrs = {} )
      @values = values
      
      #
      # Determine the base type for this enumeration. We prefer an integer type, if all values
      # are compatible, but will settle for a string type otherwise.
      
      begin
         all_integers  = true
         string_length = 0
         values.each do |value|
            all_integers  = false if all_integers and !value.is_an?(Integer)
            value_length  = value.to_s.length
            string_length = value_length if value_length > string_length
         end
      
         attrs[:base_type] = all_integers ? Schema.current.integer_type : Schema.current.text_type(string_length)
      end
      
      super attrs
   end
   
   def description()
      @values.collect{|v| v.inspect}.join("|")
   end
   
   def evaluated_type()
      base_type()
   end
   
   
end # EnumeratedType
end # Schema
end # Schemaform
