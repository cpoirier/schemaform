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


module Schemaform
module Adapters
module GenericSQL

   
   #
   # The base class for things that map Model elements into the adapter.

   class Map
      include QualityAssurance
      extend  QualityAssurance

      def initialize( context_map, model, adapter = nil )
         @context_map = context_map
         @adapter     = adapter || context_map.adapter
         @model       = model
      end
   
      attr_reader :adapter, :model, :context_map
      
      def build()
      end
   end
   
   
   class SchemaMap < Map

      def initialize( adapter, model, base_name )
         super(nil, model, adapter)
         @entity_maps = {}
         @name        = base_name + model.path
      end

      attr_reader :entity_maps

      def anchor_table_for( entity )
         return nil unless entity
         return nil unless @entity_maps.member?(entity)
         @entity_maps[entity].anchor_table
      end
      
      def build()
         @model.entities.each do |entity|
            @entity_maps[entity] = @adapter.create_entity_map(self, entity, @name)
         end

         @entity_maps.each do |name, map|
            map.build()
         end
      end
      
   end 
   
   
   class TupleMap < Map
      def initialize( context_map, model, base_name )
         super(context_map, model)
         @attributes = {}
      end
      
      def build()
         @model.attributes.each do |attribute|
            @attributes[attribute] = @adapter.create_attribute_map(self, attribute, @base_name).use do |map|
               map.build()
            end
         end
      end
   end


   class AttributeMap < Map
      def initialize( tuple_map, model, base_name )
         super(tuple_map, model)
         @tuple_map = tuple_map
         @name      = base_name + model.name
         @value_map = nil 
      end
      
      def build()
         if @model.type.collection_type? then
            if @model.type.naming_type? && @model.type.ordered_type? then
               @value_map = @adapter.create_enumeration_map(self, @model.type.member_type.tuple, @name)
            elsif @model.type.naming_type? then
               @value_map = @adapter.create_relation_map(self, @mode.type.member_type.tuple, @name)
            elsif @model.type.ordered_type? then
               @value_map = @adapter.create_list_map(self, @name)
            else
               @value_map = @adapter.create_set_map(self, )
            end
         elsif @model.type.naming_type? then
            @value_map = @adapter.create_tuple_map(self, @model.type.tuple, @name).use do |child|
               child.build()
            end
         else
            @value_map = @adapter.create_scalar_map(self, @model.type)
         end
      end
   end
   
   
   
   
   #
   # The base class for maps of things that take up space.
   
   class StorageMap < Map
      def initialize( context_map, type, base_name )
         super(context_map, type)
         @type      = type
         @base_name = base_name
      end
   end

   
   class ScalarMap < StorageMap
   end
   
   class CollectionMap < ScalarMap
   end
   
   class ListMap < CollectionMap
   end
   
   class EnumerationMap < ListMap
      def initialize( context_map, heading_type, base_name )
         super(context_map, heading_type, base_name)
         @heading_map = @adapter.create_tuple_map(self, heading_type.tuple, base_name)
      end
      
      def build()
         @heading_map.build()
      end      
   end
   
   class SetMap < CollectionMap
   end
   
   class RelationMap < SetMap
      def initialize( context_map, heading_type, base_name )
         super(context_map, heading_type, base_name)
         @heading_map = @adapter.create_tuple_map(self, heading_type.tuple, base_name)
      end
      
      def build()
         @heading_map.build()
      end      
   end
   
   
   
   
   class EntityMap < RelationMap
      def initialize( schema_map, model, base_name )
         super(schema_map, model, base_name)
         @heading_map  = nil
         @name         = base_name + model.name
      end

      attr_reader :anchor_table         
      attr_reader :relation_map
      
      def build()
         if @model.writable? then
            @heading_map = @adapter.create_tuple_map(self, @heading, @name).use do |heading_map|
               
            end
            
            
            @relation_map = @adapter.create_relation_map(self, @model, @name).use do |relation|
               relation.build()
            end
         else
            warn_todo(@model.name)
         end
      end      
   end
   
      
   
   

end # GenericSQL
end # Adapters
end # Schemaform
