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



#
# Carries runtime-typing information for an entity. This is automatically generated and should 
# never be created by the schema designer.

module Schemaform
module Model
class TypeAttribute < Attribute
   
   def initialize( type_ids, name = :type_id, type = nil )
      super(name, type || EnumeratedType.new(type_ids))
   end
   
   def recreate_in( new_context, changes = nil )
      self.class.new(nil, @name, @type).acquire_for(new_context)
   end

   def writable?()
      true
   end
   
end # TypeAttribute
end # Model
end # Schemaform