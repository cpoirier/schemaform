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
# Provides a naming context and a unit of storage within the Schemaform system.  Multiple
# Schemas can coexist within one physical database, but names are unique.

module Schemaform
module Model
class Schema
   include QualityAssurance
   extend  QualityAssurance
   
   def initialize( name, context_schema = nil, &block )
      @name        = name
      @context     = context_schema
      @objects     = {}
      @entities    = {}
      @dsl         = DefinitionLanguage.new( self )
      @connection  = nil
      @types       = {}
      @subschemas  = {}
         
      @types_are_resolved = false

      if @context.nil? then
         register_type :all     , Types::ScalarType.new(self, nil         )
         register_type :any     , Types::ScalarType.new(self, @types[:all])
         register_type :void    , Types::ScalarType.new(self, @types[:all])
         
         register_type :binary  , Types::BinaryType.new(   self, @types[:any ] )   
         register_type :text    , Types::TextType.new(     self, @types[:any ] ) 
         register_type :datetime, Types::DateTimeType.new( self, @types[:text] ) 
         register_type :real    , Types::NumericType.new(  self, @types[:any ] )    
         register_type :integer , Types::IntegerType.new(  self, @types[:real] )    

         @dsl.instance_eval do
            define_type :boolean   , :integer, :range  => 0..1
            define_type :identifier, :text   , :length => 80, :check => lambda {|i| !!i.to_sym && i.to_sym.inspect !~ /"/}
      
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
         @context.register_subschema( self )
      end
      
      @dsl.instance_eval(&block) if block_given?
      resolve_types() if @context.nil? || @context.types_are_resolved?
   end
   
   def any_type()
      return @context.exists? ? @context.any_type : @types[:any]
   end
      
      
   
   
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   
   class DefinitionLanguage
      include QualityAssurance
      
      def initialize( schema )
         @schema = schema 
      end
      

      #
      # Defines an entity within the Schema.
   
      def define( name, parent = nil, &block )
         assert_and_warn_once( parent.nil?, "TODO: derived class support" )
         @schema.register_entity Entity.new( @schema, name, parent, &block )
      end
   
   
      #
      # Defines a simple (non-entity) type.  
   
      def define_type( name, base_type = nil, modifiers = {} )
         type_check( name, [Symbol, Class] )
         type_check( modifiers, Hash )
         
         if name.is_a?(Class) then
            @schema.register_type name, Types::MappedType.new(@schema, name, base_type, modifiers, modifiers.delete(:store), modifiers.delete(:load))
         else
            @schema.register_type name, Types::ScalarType.new(@schema, base_type, modifiers)
         end
      end
   end
   
   
   
   # ==========================================================================================
   #                                      Public Interface
   # ==========================================================================================
   
   
   attr_reader :name, :context

   def top()
      return self if @context.nil?
      return @context.top
   end

   def full_name()
      @full_name = ((@context.exists? ? @context.full_name + "." : "") + @name.to_s) if @full_name.nil?
      @full_name
   end

   def types_are_resolved?()
      @types_are_resolved
   end
   
   
   #
   # Builds a contraint from pieces.

   def build_constraint( trigger, value, type )
      @@type_constraint_registry[trigger].each do |trigger_class, constraint_class|
         type.each_effective_type do |current|
            if current.is_a?(trigger_class) then # if current.class.ancestors.member?(trigger_class) then
               return constraint_class.new(value) 
            end
         end
      end
      
      return nil
   end
   
   
   #
   # Returns the Type for a name (Symbol or Class), or nil.
   
   def find_type( name, fail_if_missing = true, simple_check = false )
      return name if name.is_a?(Type)
      type_check( name, [Symbol, Class] )
      
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
         elsif @context.exists? then
            type = @context.type(name, false, true)
         end
      end   

      if fail_if_missing then
         assert( type.exists?, name.is_a?(Symbol) ? "unrecognized type [#{name}]" : "no type mapping for class [#{name.name}]" )
      end
      
      return type
   end


   #
   # Registers a named type with the schema.
   
   def register_type( name, named_type )
      assert( !@types.member?(name), "schema [#{full_name()}] already has a type named [#{name}]" )
      named_type.name = name
      @types[name] = named_type
      named_type
   end
   
   #
   # Registers an entity with the schema.
   
   def register_entity( entity )
      assert( !@entities.member?(entity.name), "schema [#{full_name()}] already has an entity named [#{entity.name}]" )
      register_type( entity.name, entity.reference_type )
      @entities[entity.name] = entity      
      entity
   end
   
   
   
   # ==========================================================================================
   #                                  Type Constraint Registry
   # ==========================================================================================

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
      assert( !@subschemas.member?(schema.name), "schema [#{full_name()}] already has a subschema named [#{schema.name}]" )
      @subschemas[schema.name] = schema
      schema
   end
   
   
   #
   # Resolves types for all fields within the Schema.
   
   def resolve_types()
      return if @types_are_resolved
      
      #
      # Resolve types for all entity fields.
      
      @entities.each do |name, entity|
         entity.resolve_field_types()
      end

      #
      # Resolve any unresolved defined types.
      
      @types.each do |name, type|
         type.resolve()
      end
      
      
      #
      # Pass the call down the chain.
      
      @subschemas.each do |subschema|
         subschema.resolve_types()
      end
      
      @types_are_resolved = true
   end
   


   
   
end # Schema
end # Model
end # Schemaform


require Schemaform.locate("type.rb"           ) 
require Schemaform.locate("type_constraint.rb")
require Schemaform.locate("entity.rb"         )

#
# Define the core type constraints.

module Schemaform
module Model

Schema.define_type_constraint :length, Types::TextType   , TypeConstraints::LengthConstraint
Schema.define_type_constraint :length, Types::BinaryType , TypeConstraints::LengthConstraint
Schema.define_type_constraint :range , Types::NumericType, TypeConstraints::RangeConstraint
Schema.define_type_constraint :check , Type              , TypeConstraints::CheckConstraint

end
end
