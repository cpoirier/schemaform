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

require Schemaform.locate("schemaform/utilities/registry.rb")


#
# Provides Type management service to the Schema.

module Schemaform
class Schema
class TypeRegistry < Registry

   def initialize( owner_description, member_description = "a type" )
      super
   end

   #
   # Registers a named type with the schema.
   
   def register( type, name = nil )
      type_check( :type, type, Type )
      super
   end

   
   #
   # Builds a type for a name and a set of modifiers. Any modifiers used will be removed
   # from the set. Any remaining are your responsibility.
   
   def build( name, modifiers = {}, fail_if_missing = true )
      if type = name.is_a?(Type) ? name : find(name, fail_if_missing) then
         type.make_specific(modifiers)
      else
         nil
      end
   end


end # TypeRegistry
end # Schema
end # Schemaform