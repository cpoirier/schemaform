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
      related_entity = @entity.schema.entities.find(entity_name)
      link_path      = nil

      if link_attribute then
         link_expression = lambda do |tuple|
            tuple.send(link_attribute)
         end
      end
      
      if link_expression then
         link_path = link_expression.call(related_entity.formula_context)
      else
         link_path = related_entity.search do |attribute, path|
            type = attribute.evaluated_type
            next unless type.is_a?(Schema::ReferenceType)
            next unless type.entity_name == @entity.name
            attribute.marker(path)
         end
      end
      
      if link_path.nil? then
         fail "couldn't find any way to relate records from #{@entity_name} to #{@entity.full_name}"
      elsif !link_path.is_an?(Attribute) then
         fail "expected Attribute result from the link expression"
      end
      
      reference_type = link_path.definition!.singular_type.evaluated_type
      if !reference_type.is_a?(Schema::ReferenceType) then
         fail "expected reference result from the link expression, found #{reference_type.class.name}"
      elsif reference_type.entity_name != @entity.name then
         fail "expected reference to #{@entity.full_name} as the result of the link expression"
      end
      
      warn_once("TODO: if the link attribute for a related lookup is part of a key, the result should be a single (optional) record")

      return @entity.type.marker(Productions::RelatedTuples.new(@entity, link_path))
   end
   
   def method_missing( symbol, *args, &block )
      super
   end


end # EntityTuple
end # ExpressionDefinition
end # Language
end # Schemaform