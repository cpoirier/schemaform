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

require Schemaform.locate("scalar_type.rb")

module Schemaform
module Model
class BooleanType < ScalarType

   def initialize( attrs )
      attrs[:default] = false unless attrs.member?(:default)
      super
   end

   #
   # Instructs the type to produce a memory representation of a stored value.
   
   def load( stored_value )
      return super if @loader
      return !!stored_value
   end
   
   
   #
   # Instructs the type to produce a storable value from a memory representation.
   
   def store( memory_value )
      return super if @storer
      return memory_value ? 1 : 0
   end

end # BooleanType
end # Model
end # Schemaform