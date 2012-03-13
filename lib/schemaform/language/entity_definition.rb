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


#
# comment

module Schemaform
module Language
class EntityDefinition
   include QualityAssurance 
      
   def self.process( schema, name, parent, &block )
      dsl = new(schema, name, parent)
      dsl.instance_eval(&block)
      dsl.entity
   end
      
   def initialize( schema, name, parent )
      @schema = schema
      @name   = name
      @parent = parent
      @entity = nil
   end
   
   attr_reader :entity


   #
   # Triggers the inline definition of an DefinedEntity in terms of a Tuple.
   
   def each( tuple_name, &block )
      assert(@entity.nil?, "you can define the entity using one \"each\" or \"as\" clause only")
      
      @entity = Schema::DefinedEntity.new(@name, @parent)
      @schema.entities.register(@entity)
      
      @entity.heading.tap do |tuple|
         assert( tuple.name.nil?, "expected unnamed tuple for EntityDefinition::each()")
         
         tuple.name = tuple_name
         @schema.tuples.register(tuple)
         TupleDefinition.process(tuple, &block)
      end
   end   
   
   
   #
   # Triggers the definition of a DerivedEntity.
   
   def as( &block )
      assert(@entity.nil?, "you can define the entity using one \"each\" or \"as\" clause only")
      assert(@parent.nil?, "derived entities cannot have a base entity"                        )
      
      @entity = Schema::DerivedEntity.new(@name, block)
      @schema.entities.register(@entity)
   end
   
   
   
   
   #
   # Defines a constraint on the entity that will be checked on save.
   
   def constrain( description, proc = nil, &block )
      assert(@entity.exists?, "you must define the entity using one \"each\" or \"as\" clause before defining any constraints")
      warn_todo("constraint support in Entity")
   end
   

   #
   # Defines a candidate key on the entity -- a subset of attributes that can uniquely identify
   # a record within the set. 
   #
   # There are several ways to call it:
   #    key *symbols
   #    key name, :on => array of symbols
   #    key name, :on => lambda expression that results in an array of attributes
   #    key name, :on => nil do |tuple|
   #       [tuple.x, tuple.y, ...]
   #    end
   #
   # Keys can support a :where clause, which is used to limit the scope of the uniqueness. These
   # "partial" keys are particuarly useful for optional attributes, where you might only want 
   # present values to be unique. The value of the :where clause should be a lambda expression that
   # takes the entity tuple as sole parameter. Note that you can only supply nil for one or the other
   # of :on or :where, if you want to use the block form. 
   
   def key( *args, &block )
      assert(@entity.exists?, "you must define the entity using one \"each\" or \"as\" clause before defining any keys")
      args = [args.collect{|symbol| symbol.to_s}.join("_and_"), {:on => args}] unless args.last.is_a?(Hash)
      
      name, hash = *args
      attributes = hash.fetch(:on) || block
      if hash.member?(:where) then
         where = hash.fetch(:where) || block
         fail_todo
      else         
         key = Schema::Key.new(@entity, name, lambda{|entity| entity.project_attributes(attributes)})
         @entity.keys.register key
         @entity.accessors.register Schema::KeyAccessor.new(key)
      end
   end
   
   
   #
   # Defines a projection of attributes that can be used to limit the data transferred back 
   # when tuples are retrieved.
   #
   # There are several ways to call it:
   #    projection name, :project => array of symbols
   #    projection name, :project => lambda expression that results in an array of attributes
   #    projection name, :project => nil do |tuple|
   #       [tuple.x, tuple.y, ...]
   #    end
   
   def projection( name, details, &block )
      assert(@entity.exists?, "you must define the entity using one \"each\" or \"as\" clause before defining any projections")
      attributes = details.fetch(:project) || block
      @entity.projections.register Schema::Projection.new(@entity, name, lambda{|entity| entity.project_attributes(attributes)})
   end
   
   
   #
   # Defines an accessor on the entity. Projections will automatically be applied to your accessors, so 
   # always project out the full entity.
   #
   # There are several ways to call it:
   #    accessor *symbols
   #    accessor name, :on => array of symbols
   #    accessor name, :where => complete query on the entity that specifies the tuples to return
   #    accessor name, :where => nil do |tuple|
   #       tuple.x == parameter(0) & tuple.y == parameter(1)
   #    end
      
   def accessor( *args, &block )
      assert(@entity.exists?, "you must define the entity using one \"each\" or \"as\" clause before defining any accessors")
      args = [args.collect{|symbol| symbol.to_s}.join("_and_"), {:on => args}] unless args.last.is_a?(Hash)
      
      name, hash = *args
      if hash.member?(:on) then
         attributes = hash[:on]
         @entity.accessors.register Schema::GeneratedAccessor.new(@entity, name, lambda{|entity| entity.project_attributes(attributes)} )
      elsif hash.member?(:where) then
         @entity.accessors.register Schema::DefinedAccessor.new(@entity, name, hash.fetch(:where) || block)
      else
         fail
      end
   end
   
   
   #
   # Defines an operation on the entity. Operations are free-form methods added to the
   # Entity class internally.
   
   def operation( name, &block )
      assert(@entity.exists?, "you must define the entity using one \"each\" or \"as\" clause before defining any operations")
      @entity.operations.register(block, name)
   end
   
   
end # EntityDefinition
end # Language
end # Schemaform
