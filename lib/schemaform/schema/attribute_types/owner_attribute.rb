#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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
# An reference to the owning ID within another collection, for hierarchical structures.
# This is automatically generated and should never be created by the schema designer.

module Schemaform
class Schema
class OwnerAttribute < Attribute
   
   def initialize( owning_collection, name = :owner_id, type = nil )
      super(name, ReferenceType.new(owning_collection))
      @owning_collection = owning_collection
   end
   
   def recreate_in( new_context, changes = nil )
      self.class.new(@owning_collection, @name, @type).acquire_for(new_context)
   end

   def writable?()
      true
   end
   
end # OwnerAttribute
end # Schema
end # Schemaform