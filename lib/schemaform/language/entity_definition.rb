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


#
# comment

module Schemaform
module Language
class EntityDefinition
   include QualityAssurance 
   
   
   def self.process( entity, &block )
      dsl = new(entity)
      dsl.instance_eval(&block)
      entity
   end

   
   def initialize( entity )
      @entity = entity
      @schema = entity.schema
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
   # Defines a candidate key on the entity -- a subset of attributes that can uniquely identify
   # a record within the set. Configation parameters are passed as a hash after the attribute
   # names. In particular, you can supply a value for :name. If you don't supply one, a name
   # will be generated from the attribute names.
   #
   #

   def key( *names_and_configuration, &block )
      configuration   = names_and_configuration.last.is_a?(Hash) ? names_and_configuration.pop : {}
      attribute_names = names_and_configuration

      assert(attribute_names.empty? ^ block.nil?, "please supply either a block or a list of attributes"            )
      assert(configuration.member?(:name) || attribute_names.not_empty?, "you must supply a name for the projection")
      
      key_name = configuration[:name] || attribute_names.collect{|name| name.to_s.identifier_case}.join("_and_").intern
      
      warn_once("does using the expression system to create keys cause problems with type resolution?")
      @entity.keys.register Schema::Key.new(@entity, key_name, @entity.project_attributes(*attribute_names, &block))
   end
   
   
   #
   # Defines a projection of attributes for simplified access. You can supply a flat list of
   # attribute names, or return an array of attributes from a block that takes the entity tuple.
   # Note that the block method is considerably more flexible, in that you can project data from
   # related tuples, as well. 
   #
   # All projections must be named. Provide it as a pair using :name as the key. You can also
   # specify the expected utilization for the projection, which will help the system to determine
   # how much effort to go to make the projection fast. A good choice for the utilization number
   # is the number of times the projection gets used by your application in one day. The system
   # will provide these statistics for you.

   def projection( *names_and_configuration, &block )
      configuration   = names_and_configuration.last.is_a?(Hash) ? names_and_configuration.pop : {}
      attribute_names = names_and_configuration

      warn_todo("projection utilization statistics")
      
      assert(attribute_names.empty? ^ block.nil?, "please supply either a block or a list of attributes")
      assert(configuration.member?(:name)       , "you must supply a name for the projection"           )

      projection_name = configuration.fetch(:name)

      warn_once("does using the expression system to create projections cause problems with type resolution?")
      @entity.projections.register Schema::Projection.new(@entity, projection_name, @entity.project_attributes(*attribute_names, &block))
   end
   
   
   #
   # Defines a constraint on the entity that will be checked on save.
   
   def constrain( description, proc = nil, &block )
      warn_todo("constraint support in Entity")
   end
   
   
   #
   # Defines an operation on the entity. Operations are free-form methods added to the
   # Entity class internally.
   
   def operation( name, &block )
      @entity.operations.register(block, name)
   end
   

   #
   # TODO: This is probably garbage, replaced by one_of(:x, :y, :z). It is less flexible, in 
   # some ways, but probably more appropriate than this. Make a decision and implement it
   #
   # #
   # # Enumerates named values within a code table.  Most entities won't need this, but for
   # # those few that do, it makes a lot of things more convenient.  The enumeration code
   # # will automatically create the necessary attributes in an empty entity, or can use any
   # # pair of appropriately typed attributes (specified with enumerate_into).  
   # #
   # # Examples:
   # #   entity :Codes do
   # #     enumerate :first, :second, :fourth, 4, :fifth
   # #   end
   # #
   # #   entity :Codes do
   # #     attribute :a_name , identifier_type()
   # #     attribute :a_value, integer_type()   
   # #     
   # #     enumerate :first, :second, :fourth, 4, :fifth
   # #   end
   # #
   # #   entity :Codes do
   # #     attribute :a_name , identifier_type()
   # #     attribute :a_value, integer_type()   
   # #     attribute :public , boolean_type()
   # #
   # #     enumerate do
   # #       define :first , 1, true
   # #       define :second, 2, false
   # #     end
   # #   end
   # 
   # def enumerate( *data, &block )
   #    dsl = self
   #    @entity.instance_eval do
   #       check do
   #          assert( @base_entity.nil?, "enumerated entities cannot have a base" )
   #          assert( @enumeration.nil?, "entity is already enumerated"           )
   #       end
   #       
   #       if @heading.empty? then
   #          @heading.define do 
   #             required :name , Symbol
   #             required :value, Integer
   #          end
   #          dsl.key :name
   #       else
   #          check do
   #             assert( @attributes.length >= 2, "an enumerated entity needs at least name and value attributes" )
   #          end
   #          
   #          # TODO type check the first two attributes, once you figure out how best to do it
   #       end
   # 
   #       @enumeration = Enumeration.new( self )
   #       
   #       if block then
   #          @enumeration.fill(block)
   #       else
   #          check do
   #             assert( @heading.length == 2, "to use the simple enumeration form, the entity must have only two attributes" )
   #          end
   # 
   #          @enumeration.fill do
   #             value = 1
   #             until data.empty?
   #                name  = data.shift
   #                value = data.shift if data.first.is_an?(Integer)
   #          
   #                check do
   #                   assert( name.is_a?(Symbol), "expected a symbol or value, found #{name.class.name}" )
   #                end
   #          
   #                define name, value
   #                value += 1
   #             end
   #          end
   #       end
   #    end
   # end

end # EntityDefinition
end # Language
end # Schemaform
