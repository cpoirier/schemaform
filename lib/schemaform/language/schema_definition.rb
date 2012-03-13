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



module Schemaform
module Language
class SchemaDefinition
   include QualityAssurance
   
   def self.process( schema, &block )
      schema.tap do 
         dsl = new(schema)
         schema.enter do
            dsl.instance_eval(&block)
            schema.verify()
         end
      end
   end

   def initialize(schema, &block)
      @schema = schema
   end
   

   #
   # Defines an entity within the Schema.

   def define_entity( name, parent = nil, &block )
      if parent && !parent.is_an?(Schema::Entity) then
         parent = @schema.entities.find(parent, checks_enabled?)
      end

      EntityDefinition.process(@schema, name, parent, &block)
   end
   
      
   #
   # Defines a tuple within the Schema.
   
   def define_tuple( name, &block )
      TupleDefinition.build(name, &block)
   end


   #
   # Defines a simple (non-entity) type.  

   def define_type( name, base_name = nil, modifiers = {} )
      fail_todo "not refactored yet"
      @schema.instance_eval do
         check do
            type_check( :name, name, [Symbol, Class] )
            type_check( :modifiers, modifiers, Hash )
         end

         if base_name && !@types.member?(base_name) then
            fail_todo "deferred types"
         else
            modifiers[:base_type] = @types[base_name]
            @types.register modifiers[:name], UserDefinedType.new(modifiers)
         end
      end
   end
   
   
   #
   # Adds attributes to an existing tuple type.
   
   def augment_tuple( name, &block )
      tuple_type = @schema.find_tuple_type(name) 
      tuple_type.define( &block )
   end


end # SchemaDefinition
end # Language
end # Schemaform