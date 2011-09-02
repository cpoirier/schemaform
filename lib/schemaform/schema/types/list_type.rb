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

require Schemaform.locate("collection_type.rb")

#
# A container type that holds an ordered list of something.

module Schemaform
class Schema
class ListType < CollectionType

   def self.build( member_type, attrs = {} )
      attrs[:context    ] = member_type.schema unless attrs.member?(:context)
      attrs[:member_type] = member_type
      
      if member_type.is_a?(TupleType) then
         TabulationType.new(attrs)
      else
         new(attrs)
      end
   end
   
   def description()
      "list of #{member_type.description}"
   end
   
   def print_to( printer, label = "list of" )
      super
   end
   
   
end # ListType
end # Schema
end # Schemaform
