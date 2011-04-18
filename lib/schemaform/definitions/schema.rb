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
# Provides a naming context and a unit of storage within the Schemaform system.

module Schemaform
module Definitions
class Schema < Definition
   
   @@schemas = {}
   @@monitor = Monitor.new()

   def self.[]( name )
      @@monitor.synchronize { @@schemas[name] }
   end
   
   def self.defined?( name )
      @@monitor.synchronize { @@schemas.member?(name) }
   end
   
   def self.define( name, &block )
      @@monitor.synchronize do
         new( name, &block ).tap do |schema|
            @@schemas[name] = schema
         end
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

            register_type Entity.new( name, parent, self, &block )
         end
      end
      
      
      #
      # Defines a tuple type within the Schema.
      
      def define_tuple( name, &block )
         @schema.instance_eval do
            check do
               register_type TupleType.new( self, name, &block )
            end
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

            if base_name && !@types.member?(base_name) then
               fail "TODO: deferred types"
            else
               modifiers[:name     ] = name
               modifiers[:base_type] = base_name
               modifiers[:context  ] = self
               
               register_type UserDefinedType.new(modifiers)
            end
         end
      end
      
      
      #
      # Adds attributes to an existing tuple type.
      
      def augment_tuple( name, &block )
         tuple_type = @schema.find_tuple_type(name) 
         tuple_type.define( &block )
      end
   end
   
   
   
   # ==========================================================================================
   #                                      Public Interface
   # ==========================================================================================
   
   
   #
   # Registers a named type with the schema.
   
   def register_type( type )
      type_check( :type, type, Type )
      return if @types.member?(type.name) && @types[type.name].object_id == type.object_id
      
      # if type.is_a?(TupleType) then
      #    check { assert( !@tuple_types.member?(type.name), "schema [#{full_name}] already has a tuple type named [#{type.name}]" ) }
      #    @tuple_types[type.name] = type
      # end
      # 
      # if type.is_an?(Entity) then
      #    check { assert( !@entities.member?(type.name), "schema [#{full_name}] already has an entity named [#{type.name}]" ) }
      #    @entities[type.name] = type
      # end
      # 
      # if type.is_a?(Relation) then
      #    check { assert( !@relations.member?(type.name), "schema [#{full_name}] already has a relation named [#{type.name}]" ) }
      #    @relations[type.name] = type      
      # end

      check { assert( !@types.member?(type.name), "schema [#{full_name}] already has a type named [#{type.name}]" ) }

      @types[type.name] = type
      return type
   end
   
   
   #
   # Builds a type for a name and a set of constraints.
   
   def build_type( name, modifiers = {}, fail_if_missing = true )
      type = name.is_a?(Type) ? name : find_type(name, fail_if_missing)
      type.make_specific(modifiers)
   end


   def types_are_resolved?()
      @types_are_resolved
   end
   
   attr_reader :supervisor
   
   def any_type()
      return @types[:any]
   end
   
   def rid_type()
      return @types[:rid]
   end
      
   def each_entity() 
      @entities.each do |name, entity|
         yield( entity )
      end
   end
   
   def each_tuple_type()
      @types.each do |name, type|
         resolved = type.resolve()
         yield( resolved ) if resolved.tuple_type?
      end
   end

      
   #
   # Returns the Type for a name (Symbol or Class), or nil.
   
   def find_type( name, fail_if_missing = true )
      return name if name.nil? || name.is_a?(Type) 
      check { type_check(:name, name, [Symbol, Class]) }
      
      type    = nil
      current = name
      while current && type.nil?
         type    = @types[current] if @types.member?(current)
         current = current.is_a?(Class) ? current.superclass : nil
      end

      return type.resolve(:reference) if type
      return nil if fail_if_missing
      fail( name.is_a?(Symbol) ? "unrecognized type [#{name}]" : "no type mapping for class [#{name.name}]" )
   end
   
   
   #
   # Returns the TupleType (type) for a name, or nil.
   
   def find_tuple_type( name, fail_if_missing = true )
      return name if name.is_a?(TupleType)
      type_check( :name, name, Symbol )
      
      return @tuple_types[name] if @tuple_types.member?(name)
      return nil unless fail_if_missing
      fail( "unrecognized tuple type [#{name}]" )
   end
   
   
   #
   # Returns an Entity or other named Relation for a name (Symbol), or nil.
   
   def find_relation( name, fail_if_missing = true )
      return name if name.is_a?(Relation)
      type_check( :name, name, Symbol )
      
      return @relations[name] if @relations.member?(name)
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
   #                                      Type Constraints
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

   def initialize( name, &block )
      super( nil, name )
      
      @dsl         = DefinitionLanguage.new( self )
      @types       = {}
      @tuple_types = {}
      @relations   = {}
      @entities    = {}
      @supervisor  = TypeResolutionSupervisor.new( self )
         
      @types_are_resolved = false

      register_type CatchAllType.new(:name => :all     , :context   => self)
      register_type     VoidType.new(:name => :void    , :base_type => @types[:all])
      register_type         Type.new(:name => :any     , :base_type => @types[:all])
                                                       
      register_type   StringType.new(:name => :binary  , :base_type => @types[:any]) ; warn_once( "BUG: does the binary type need a different loader?" )
      register_type   StringType.new(:name => :text    , :base_type => @types[:any])
      register_type  BooleanType.new(:name => :boolean , :base_type => @types[:any])
      register_type DateTimeType.new(:name => :datetime, :base_type => @types[:any])
      register_type  NumericType.new(:name => :real    , :base_type => @types[:any] , :default => 0.0 )
      register_type  NumericType.new(:name => :integer , :base_type => @types[:real], :default => 0   )
      
      @dsl.instance_eval do
         define_type :identifier, :text, :length => 80, :check => lambda {|i| !!i.to_sym && i.to_sym.inspect !~ /"/}
      end
      
      @dsl.instance_eval(&block) if block_given?
      resolve_types()
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
         
         puts "monitoring #{description}"
         assert( !@entries.member?(scope), "detected loop while trying to resolve #{description}" )
         return annotate_errors( annotation ) do
            check( @entries.push_and_pop(scope) { yield() } ) do |type|
               assert( type.exists?, "unable to resolve type for [#{description}]" )
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
         if scope.is_an?(Array) then
            [scope_description( scope.first ), "(" + scope.slice(1..-1).collect{|v| v.to_s}.join(" ") + ")"].join( " " )
         else
            "#{class_name_for(scope)} #{scope.full_name}"
         end
      end
      
   end # TypeResolutionSupervisor

   
   
   
   # ==========================================================================================
   #                                           Mapping
   # ==========================================================================================
   
   #
   # Maps the Schema into runtime representation.
   
   def lay_out()
      @master = Layout::Master.build(@name) do |builder|
         @entities.each do |entity|
            entity.lay_out( builder )
         end
      end
   end
   
   
   
   
end # Schema
end # Definitions
end # Schemaform


