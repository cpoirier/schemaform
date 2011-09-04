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


module Schemaform
class Schema
class ReferenceType < Type

   def initialize( entity_name, attrs = {} )
      attrs.delete(:base_type)
      if entity_name.is_an?(Entity) then
         entity          = entity_name
         attrs[:context] = entity unless attrs.member?(:context)
         super attrs
         @entity_name = entity.name
         @entity      = entity
         warn_once("is there a downside to initializing a ReferenceType directly to an Entity?")
      else
         super attrs
         type_check(:entity_name, entity_name, Symbol)
         @entity_name = entity_name
         @entity      = nil
      end
   end
   
   attr_reader :entity_name
   
   def base_type()      
      return @base_type if @base_type.exists?
      if referenced_entity && referenced_entity.base_entity.exists? then
         @base_type = ReferenceType.new(referenced_entity.base_entity)
      else
         nil
      end
   end
   
   def referenced_entity()
      @entity ||= schema.entities.find(@entity_name)
   end
   
   def description()
      "#{referenced_entity.name} reference"
   end

   def attribute?( attribute_name )
      referenced_entity.attribute?(attribute_name)
   end
   
   def verify()
      assert(referenced_entity(), "unable to find referenced entity #{@entity_name}")
   end
   
   def ==( rh_type )
      return (rh_type.is_a?(ReferenceType) && rh_type.referenced_entity == referenced_entity) || super
   end

end # ReferenceType
end # Schema
end # Schemaform
