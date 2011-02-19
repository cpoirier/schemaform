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

require 'monitor'


#
# Provides a naming context and a unit of storage within the Schemaform system.  Individual Schemas
# are separate from each other, with the exception that a nested Schema inherits the names defined
# in its context.  Multiple separate Schemas can coexist within one physical database, provided 
# either unique names or separate connection prefices.  

module Schemaform
module Definitions
class Schema < Definition
   
   def initialize( name, context_schema = nil, &block )
      super( context_schema, name )
      
      @dsl        = DefinitionLanguage.new( self )
      @types      = {}
      @subschemas = {}
      @relations  = {}
      @entities   = {}
      @supervisor = context_schema ? context_schema.supervisor : TypeResolutionSupervisor.new( self )
         
      @types_are_resolved = false

      if root == self then
         register_type :all     , ScalarType.new(   nil, self     )
         register_type :any     , ScalarType.new(   @types[:all]  )
         register_type :void    , ScalarType.new(   @types[:all]  )
         
         register_type :binary  , BinaryType.new(   @types[:any ] )   
         register_type :text    , TextType.new(     @types[:any ] ) 
         register_type :datetime, DateTimeType.new( @types[:text] ) 
         register_type :real    , NumericType.new(  @types[:any ] )    
         register_type :integer , IntegerType.new(  @types[:real] )    

         @dsl.instance_eval do
            define_type :boolean   , :integer, :range  => 0..1
            define_type :identifier, :text   , :length => 80, :check => lambda {|i| !!i.to_sym && i.to_sym.inspect !~ /"/}
      
            define_type Float     , :real
            define_type Integer   , :integer
            define_type String    , :text
            define_type Symbol    , :identifier, :load => lambda {|s| s.intern}
            define_type IPAddr    , :text, :length => 40
            define_type TrueClass , :boolean, :store => 1, :load => lambda {|v| !!v }
            define_type FalseClass, :boolean, :store => 0, :load => lambda {|v| !!v }
            define_type Time      , :datetime,
                                    :store => lambda {|t| utc = t.getutc; utc.strftime("%Y-%m-%d %H:%M:%S") + (utc.usec > 0 ? ".#{utc.usec}" : "") },
                                    :load  => lambda {|s| year, month, day, hour, minute, second, micros = *s.split(/[:\-\.] /); Time.utc(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i, second.to_i, micros.to_i)}  
         end
      else
         context_schema.register_subschema( self )
      end
      
      @dsl.instance_eval(&block) if block_given?
      resolve_types() if context_schema.nil? || context_schema.types_are_resolved?
   end
   
   attr_reader :supervisor
   
   def any_type()
      return find_type(:any)
   end
      
      
   def each_entity() 
      @entities.each do |name, entity|
         yield( entity )
      end
   end
   
   def each_subschema()
      @subschemas.each do |name, subschema|
         yield( subschema )
      end
   end
   
   
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   
   class DefinitionLanguage
      def initialize( schema )
         @schema = schema 
      end
      

      #
      # Defines an entity within the Schema.
   
      def define_entity( name, parent = nil, &block )
         @schema.instance_eval do
            check do
               assert_and_warn_once( parent.nil?, "TODO: derived class support" )
            end

            register_entity Entity.new( name, parent, self, &block )
         end
      end
   
   
      #
      # Defines a simple (non-entity) type.  
   
      def define_type( name, base_name = nil, modifiers = {} )
         @schema.instance_eval do
            check do
               type_check( :name, name, [Symbol, Class] )
               type_check( :modifiers, modifiers, Hash )
            end

            base_type = TypeReference.new(self, base_name, modifiers)
            if name.is_a?(Class) then
               register_type name, MappedType.new(name, base_type, modifiers.delete(:load), modifiers.delete(:store), @schema)
            else
               register_type name, base_type
            end
         end
      end
   end
   
   
   
   # ==========================================================================================
   #                                      Public Interface
   # ==========================================================================================
   
   
   def types_are_resolved?()
      @types_are_resolved
   end
   
   
   #
   # Returns the Type for a name (Symbol or Class), or nil.
   
   def find_type( name, fail_if_missing = true, simple_check = false )
      return name if name.is_a?(Type)
      check { type_check(:name, name, [Symbol, Class]) }

      
      #
      # If attempting to resolve a Class, we will try for the requested Class or any of its
      # base classes.  Otherwise, we are doing a simple check of just the specified name in 
      # this or a context Schema.
      
      type = nil
      if name.is_a?(Class) and !simple_check then
         name.ancestors.each do |current|
            break if type = find_type(current, false, true)
         end
      else
         if @types.member?(name) then
            type = @types[name]
         elsif @schema.exists? then
            type = schema.find_type(name, false, true)
         end
      end   

      if fail_if_missing then
         assert( type.exists?, name.is_a?(Symbol) ? "unrecognized type [#{name}]" : "no type mapping for class [#{name.name}]" )
      end
      
      return type.resolve()
   end
   
   
   #
   # Returns an Entity or other named Relation for a name (Symbol), or nil.
   
   def find_relation( name, fail_if_missing = true )
      return name if name.is_a?(Relation)
      type_check( :name, name, Symbol )
      
      return @relations[name] if @relations.member?(name)
      return schema.find_relation(name, fail_if_messing) if schema
      return nil unless fail_if_missing
      fail( "unrecognized relation [#{name}]" )
   end
   
   #
   # Returns an Entity (only) for a name (Symbol), or nil.
   
   def find_entity( name, fail_if_missing = true )
      return name if name.is_a?(Entity)
      type_check( :name, name, Symbol )
      
      return @entities[name] if @entities.member?(name)
      return schema.find_entity(name, fail_if_missing) if schema
      return nil unless fail_if_missing
      fail( "unrecognized entity [#{name}]" )
   end
   
   
   
   


   # ==========================================================================================
   #                                      Type Resolution
   # ==========================================================================================

   
   #
   # Resolves types for all attributes within the Schema.
   
   def resolve_types()
      return if @types_are_resolved


      #
      # Resolve any defined types first.
      
      @types.each do |name, type|
         type.resolve()
      end
   
      #
      # Resolve entities next.
      
      @entities.each do |name, entity|
         entity.resolve()
      end
      
      #
      # Pass the call down the chain.
      
      @subschemas.each do |subschema|
         subschema.resolve_types()
      end
      
      @types_are_resolved = true
   end
   

   #
   # A helper class that ensures type resolution errors are noticed and reported.
   
   class TypeResolutionSupervisor
      include QualityAssurance
      
      def initialize( schema )
         @schema  = schema
         @entries = []
      end
      
      def monitor( scope, report_worthy = true )
         description = scope_description(scope)
         annotation  = report_worthy ? { :scope => description } : {}
         
         assert( !@entries.member?(scope), "detected loop while trying to resolve #{description}" )
         return annotate_errors( annotation ) do
            check( @entries.push_and_pop(scope) { yield() } ) do |type|
               assert( type.exists?, "unable to resolve type for [#{class_name_for(scope)} #{scope.full_name}]" )
               type_check( :type, type, Type )
               warn_once( "DEBUG: #{description} resolved to #{class_name_for(type)} #{type.description}" ) if report_worthy
            end
         end
      end

   private
      def class_name_for( object )
         object.class.name.gsub("Schemaform::Definitions::", "")
      end
      
      def scope_description( scope )
         "#{class_name_for(scope)} #{scope.full_name}"
      end
      
   end # TypeResolutionSupervisor

   
   
   
   # ==========================================================================================
   #                                       Type Constraints
   # ==========================================================================================


   #
   # Builds a contraint from pieces.

   def build_constraint( trigger, value, type )
      if defined?(@@type_constraint_registry) then
         @@type_constraint_registry[trigger].each do |trigger_class, constraint_class|
            type.each_effective_type do |current|
               if current.is_a?(trigger_class) then # if current.class.ancestors.member?(trigger_class) then
                  return constraint_class.new(value) 
               end
            end
         end
      end
      
      return nil
   end
   

   #
   # Associates a TypeConstraint with a StorableType for use when defining types.  The constraint
   # must be registered before you attempt to use it in a Schema definition.  
   
   def self.define_type_constraint( trigger, type_class, constraint_class )
      @@type_constraint_registry = {} if !defined?(@@type_constraint_registry) || @@type_constraint_registry.nil?
      @@type_constraint_registry[trigger] = {} unless @@type_constraint_registry.member?(trigger)
      @@type_constraint_registry[trigger][type_class] = constraint_class
   end
   
   
   



protected

   # ==========================================================================================
   #                                          Internals
   # ==========================================================================================

   def register_subschema( schema )
      check do
         assert( !@subschemas.member?(schema.name), "schema [#{@path.join(".")}] already has a subschema named [#{schema.name}]" )
      end
      
      @subschemas[schema.name] = schema
      return schema
   end
   

   #
   # Registers a named type with the schema.
   
   def register_type( name, named_type )
      check do
         assert( !@types.member?(name), "schema [#{full_name}] already has a type named [#{name}]" )
      end
      
      named_type.name = name
      @types[name] = named_type
      return named_type
   end
   
   
   #
   # Registers a named relation with the schema.
   
   def register_relation( relation )
      check do
         assert( !@relations.member?(relation.name), "schema [#{@path.join(".")}] already has a relation named [#{relation.name}]" )
      end
      
      @relations[relation.name] = relation      
      return relation
   end

   
   #
   # Registers an entity with the schema.
   
   def register_entity( entity )
      check do
         assert( !@entities.member?(entity.name), "schema [#{@path.join(".")}] already has an entity named [#{entity.name}]" )
      end
      
      register_type( entity.name, entity.reference_type )
      register_relation( entity )
      @entities[entity.name] = entity      
      return entity
   end
   
   
   
   
end # Schema
end # Definitions
end # Schemaform


require Schemaform.locate("type.rb"           ) 
require Schemaform.locate("type_constraint.rb")
require Schemaform.locate("entity.rb"         )

#
# Define the core type constraints.

module Schemaform
module Definitions
class Schema
   define_type_constraint :length, TextType   , TypeConstraints::LengthConstraint
   define_type_constraint :length, BinaryType , TypeConstraints::LengthConstraint
   define_type_constraint :range , NumericType, TypeConstraints::RangeConstraint
   define_type_constraint :check , Type       , TypeConstraints::CheckConstraint
end
end
end
