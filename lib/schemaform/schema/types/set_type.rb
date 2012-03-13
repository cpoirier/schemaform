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

require Schemaform.locate("collection_type.rb")


#
# A container type that can hold no duplicates and has no inherent ordering.

module Schemaform
class Schema
class SetType < CollectionType
   
   #
   # Returns an Element wrapper on this type.
   
   def to_element( context_collection = nil )
      Set.new(@member_type.to_element(context), context_collection)
   end

   
end # SetType
end # Schema
end # Schemaform