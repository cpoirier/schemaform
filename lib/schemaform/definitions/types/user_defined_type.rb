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
# Represents all user-defined types that have an existing type name as base type. All user-
# defined type have a name.

module Schemaform
module Definitions
class UserDefinedType < Type
   
   #
   # Builds a UDT from parts.
   
   def self.build( schema, name, base_type, modifiers = {} )
      loader    = modifiers.delete(:loader)
      storer    = modifiers.delete(:storer)
      default   = modifiers.delete(:default)
      base_type = schema.build_type(base_type, modifiers)
      checks    = build_checks(modifiers)
      
      assert(modifiers.empty?, "unrecognized modifiers", modifiers)
      new(name, base_type, default, loader, storer, checks)
   end

   def initialize( attrs )
      super
   end
   
      

end # UserDefinedType
end # Definitions
end # Schemaform
