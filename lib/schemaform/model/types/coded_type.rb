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

require Schemaform.locate("enumerated_type.rb")

#
# An enumerated type that maps between names and values. Internally, all CodedType values are
# numeric, but you can specify the values with symbols that will be translated for you.

module Schemaform
module Model
class CodedType < EnumeratedType

   def initialize( map, attrs = {} )
      values = map.values.uniq
      super(values, attrs)
      @map = map
   end

end # CodedType
end # Model
end # Schemaform