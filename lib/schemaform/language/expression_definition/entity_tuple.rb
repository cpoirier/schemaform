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

require Schemaform.locate("tuple.rb")


#
# Provides access to a Entity-examplar Tuple and its attributes. This is different from the 
# basic Tuple marker in that it adds support for references (which must always be homed in 
# an entity).

module Schemaform
module Language
module ExpressionDefinition
class EntityTuple < Tuple

   def initialize( entity, production = nil )
      super(entity.heading, production)
      @entity = entity
   end
   
   def entity!()
      @entity
   end
   
   def related!( entity_name, link_attribute = nil, &link_expression )
      related_entity = @definition.schema.entities.find(entity_name)
      link_path      = nil
      
      if link_expression then
         link_path = link_expression.call(related_entity.formula_context)
      elsif link_attribute then
         fail "TODO: attribute name shortcut"
      else
         link_path = related_entity.search do |attribute, path|
            next unless attribute.definition.is_a?(Schema::Scalar)
            next unless attribute.definition.evaluated_type.is_a?(Schema::ReferenceType)
            next unless attribute.definition.evaluated_type.entity_name == @entity.name
            attribute.marker(path)
         end
      end
      
      if link_path.nil? then
         fail "couldn't find any way to relate records from #{@entity_name} to #{@entity.full_name}"
      elsif !link_path.is_an?(Attribute) then
         fail "expected Attribute result from the link expression"
      elsif !link_path._definition.evaluated_type.is_a?(Schema::ReferenceType) || link_path._definition.evaluated_type.entity_name != @entity.name then
         fail "expected reference to #{@entity.full_name} as the result of the link expression"
      end
      
      warn_once("TODO: if the link attribute for a related lookup is part of a key, the result should be a single (optional) record")

      relation
      
      
      link_path
   end
   
   def method_missing( symbol, *args, &block )
      super
   end


end # EntityTuple
end # ExpressionDefinition
end # Language
end # Schemaform