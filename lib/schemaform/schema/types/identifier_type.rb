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
# Similar to a ReferenceType, except that the IdentifierType creates the thing that can be
# referenced.

module Schemaform
class Schema
class IdentifierType < Type

   def initialize( entity, attrs = {} )
      attrs[:context  ] = entity unless attrs.member?(:context)
      attrs[:base_type] = attrs.fetch(:context).schema.identifier_type unless attrs.member?(:base_type)
      super attrs
      @entity = entity
   end
   
   attr_reader :entity
   
   def naming_type?
      true
   end
   
   def referenced_entity()
      @entity
   end
   
   def description()
      "#{@entity.name} identifier"
   end
   
   
   

end # IdentifierType
end # Schema
end # Schemaform