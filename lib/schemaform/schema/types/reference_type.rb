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


module Schemaform
class Schema
class ReferenceType < Type

   def initialize( collection, attrs = {} )
      attrs.delete(:base_type)
      super attrs
      
      @collection = collection
   end
   
   def base_type()      
      fail_todo "convert from old ReferenceType code"
      return @base_type if @base_type.exists?
      if referenced_entity && referenced_entity.base_entity.exists? then
         @base_type = ReferenceType.new(referenced_entity.base_entity)
      else
         nil
      end
   end
   
   def referenced_collection()
      @collection
   end
   
   def description()
      "#{@collection.full_name} reference"
   end

   def ==( rh_type )
      return (rh_type.is_a?(ReferenceType) && rh_type.referenced_collection == referenced_collection) || super
   end

end # ReferenceType
end # Schema
end # Schemaform
