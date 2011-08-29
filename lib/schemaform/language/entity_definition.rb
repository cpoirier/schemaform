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

require Schemaform.locate("relation_definition.rb")

#
# comment

module Schemaform
module Language
class EntityDefinition < RelationDefinition
   include QualityAssurance 
   
   
   def initialize( entity )
      super(entity)
      @entity = entity
   end


   #
   # Triggers the inline definition of the Tuple for the Entity.
   
   def each( tuple_name, &block )
      @entity.declared_heading.tap do |tuple|
         assert( tuple.name.nil?, "expected unnamed tuple for TupleDefinition::each()")
         
         tuple.name = tuple_name
         @schema.tuples.register(tuple)
         TupleDefinition.process(tuple, &block)
      end

      @entity.heading.rename(:id, @entity.id())
   end   
   
   
   #
   # Defines a constraint on the entity that will be checked on save.
   
   def constrain( description, proc = nil, &block )
      warn_todo("constraint support in Entity")
   end
   
end # EntityDefinition
end # Language
end # Schemaform
