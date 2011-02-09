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

require Schemaform.locate("relation.rb")
require Schemaform.locate("tuple.rb"   )


#
# A single entity within the schema.

module Schemaform
module Definitions
class Entity < Relation
      
   def initialize( name, base_entity, schema, &block )
      super( base_entity || schema, Tuple.new(self), name )

      @base_entity = base_entity
      @keys        = {}
      @primary_key = nil
      @enumeration = nil
      @dsl         = DefinitionLanguage.new( self )
      @expression  = Expressions::Relations::Entity.new( self )

      @reference_type = ReferenceType.new( self )
      
      if @base_entity then
         @base_entity.heading.each_field do |field|
            @tuple.add_field field
         end
      end
      
      @dsl.instance_eval(&block) if block_given?
   end
   
   attr_reader :keys, :reference_type, :expression
   attr_accessor :enumeration

   def has_base_entity?()
      @base_entity.exists?
   end
   
   def description()
      full_name() + " " + super
   end
   
   def primary_key()
      return @primary_key unless @primary_key.nil?
      return @base_entity.primary_key unless @base_entity.nil?
      return nil
   end
   
   
   #
   # Returns true if the named field is defined in this or any base entity.
   
   def field?( name )
      return @heading.field?(name)
   end
   
   #
   # Returns true if the named key is defined in this or any base entity.
   
   def key?( name )
      return true if @keys.member?(name)
      return @base_entity.key?(name) if @base_entity.exists?
      return false
   end
   
   #
   # If true, this entity is enumerated.
   
   def enumerated?()
      @enumeration.exists?
   end
   
   def resolve()
      supervisor.monitor(self) do
         warn_once( "TODO: key resolution and other entity-level resolution jobs" )
         warn_once( "TODO: create a relation type" )
         @heading.resolve()
         self
      end
   end
   

   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   
   class DefinitionLanguage
      def initialize( entity )
         @entity = entity
      end
      
      
      #
      # Triggers the inline definition of the Tuple for the Entity.
      
      def each( tuple_name, tuple_base = nil, &block )
         @entity.heading.define(&block)
      end
      
      
      #
      # Defines the Entity heading in terms of a named Tuple.
      
      def of( tuple_name )
         @entity.change_heading( tuple_name )
      end
      
      
   
      #
      # Defines a candidate key on the entity -- a subset of fields that can uniquely identify
      # a record within the set.  You can name the key by passing a one-entry hash instead of
      # an array of field name.  If you supply no keys, the full set of stored fields is used
      # as the key.  Note: [:x, :y] is the same key as [:y, :x].  The system will not stop
      # you from making both, but there is likely no benefit to you for doing so.
      #
      # Examples:
      #   key :field_name
      #   key :field_name, :other_field_name
      #   key :key_name => :field_name
      #   key :key_name => [:field_name]
      #   key :key_name => [:field_name, :other_field_name]
   
      def key( *names )
         @entity.instance_eval do 
            key_name = nil
            if names[0].is_a?(Hash) then
               key_name = names[0].keys.first
               names = names[0][key_name].as_array
            end
      
            key_name = names.collect{|name| name.to_s}.join("_and_") if key_name.nil?
      
            check do
               assert( !key?(key_name), "key name #{key_name} already exists in entity #{@name}" )
               names.each do |name|
                  assert( field?(name), "key field #{name} is not a member of entity #{@name}" )
               end
            end
            
            @keys[key_name] = Key.new( self, key_name, names )
         
            #
            # For the sake of expediency, we are making the primary key the first key 
            # in the entity (or any of its base entities).  In the future, something more
            # intelligent might be useful.
            
            @primary_key = key_name if primary_key.nil?
         end
      end
   
   
      #
      # Enumerates named values within a code table.  Most entities won't need this, but for
      # those few that do, it makes a lot of things more convenient.  The enumeration code
      # will automatically create the necessary fields in an empty entity, or can use any
      # pair of appropriately typed fields (specified with enumerate_into).  
      #
      # Examples:
      #   entity :Codes do
      #     enumerate :first, :second, :fourth, 4, :fifth
      #   end
      #
      #   entity :Codes do
      #     field :a_name , identifier_type()
      #     field :a_value, integer_type()   
      #     
      #     enumerate :first, :second, :fourth, 4, :fifth
      #   end
      #
      #   entity :Codes do
      #     field :a_name , identifier_type()
      #     field :a_value, integer_type()   
      #     field :public , boolean_type()
      #
      #     enumerate do
      #       define :first , 1, true
      #       define :second, 2, false
      #     end
      #   end

      def enumerate( *data, &block )
         dsl = self
         @entity.instance_eval do
            check do
               assert( @base_entity.nil?, "enumerated entities cannot have a base" )
               assert( @enumeration.nil?, "entity is already enumerated"           )
            end
            
            if @heading.empty? then
               @heading.define do 
                  required :name , :identifier
                  required :value, :integer
               end
               dsl.key :name
            else
               check do
                  assert( @fields.length >= 2, "an enumerated entity needs at least name and value fields" )
               end
               
               # TODO type check the first two fields, once you figure out how best to do it
            end
      
            @enumeration = Enumeration.new( self )
            
            if block then
               @enumeration.fill(block)
            else
               check do
                  assert( @heading.length == 2, "to use the simple enumeration form, the entity must have only two fields" )
               end

               @enumeration.fill do
                  value = 1
                  until data.empty?
                     name  = data.shift
                     value = data.shift if data.first.is_an?(Integer)
               
                     check do
                        assert( name.is_a?(Symbol), "expected a symbol or value, found #{name.class.name}" )
                     end
               
                     define name, value
                     value += 1
                  end
               end
            end
         end
      end
   end
   
   

end # Entity
end # Definitions
end # Schemaform


require Schemaform.locate("key.rb")
require Schemaform.locate("enumeration.rb")

