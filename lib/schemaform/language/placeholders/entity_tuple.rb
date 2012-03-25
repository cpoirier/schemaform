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

require Schemaform.locate("tuple.rb")


#
# Provides access to a Entity-examplar Tuple and its attributes. This is different from the 
# basic Tuple marker in that it adds support for references (which must always be homed in 
# an entity).

module Schemaform
module Language
class EntityTuple < Tuple

   def initialize( entity, production = nil )
      super(entity.heading, production)
      @entity = entity
      @names  = entity.pedigree.collect{|e| e.name}
   end
   
   def get_related( entity_name, link_attribute = nil, &link_expression )
      p @entity.path
      related_entity = @entity.schema.entities.find(entity_name)
      link_path      = nil

      if link_attribute then
         link_expression = lambda do |tuple|
            tuple.send(link_attribute)
         end
      end
      
      if link_expression then
         link_path = link_expression.call(related_entity.root_tuple.placeholder)
      else
         link_path = related_entity.search do |attribute, path|
            type = attribute.evaluated_type
            next unless type.is_a?(Model::EntityReferenceType)
            next unless @names.member?(type.entity_name)
            attribute.placeholder(path)
         end
      end
      
      if link_path.nil? then
         fail "couldn't find any way to relate records from #{related_entity.full_name} to #{@entity.full_name}"
      elsif !link_path.is_an?(Attribute) then
         fail "expected Attribute result from the link expression; found #{link_path.class.name} instead"
      end
      
      reference_type = link_path.instance_variable_get(:@definition).singular_type.evaluated_type
      if !reference_type.is_a?(Model::EntityReferenceType) then
         fail "expected reference result from the link expression, found #{reference_type.class.name}"
      elsif !@names.member?(reference_type.entity_name) then
         fail "expected reference to #{@entity.full_name} as the result of the link expression"
      end
      
      warn_todo("if the link attribute for a related lookup is part of a key, the result should be a single (optional) record")

      return Model::SetType.build(related_entity.reference_type).placeholder(Productions::RelatedTuples.new(@entity, link_path))
   end
   
   def method_missing( symbol, *args, &block )
      super
   end

   def get_description()
      "0x#{self.object_id.to_s(16)} #{@entity.heading.name} #{@type.description}"
   end


end # EntityTuple
end # Language
end # Schemaform