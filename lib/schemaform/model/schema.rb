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
      @name       = name
      @context    = context_schema
      @objects    = {}
      @entities   = {}
      @dsl        = DefinitionLanguage.new( self )
      @connection = nil
      @types      = {}
      
      @constraint_templates  = {}

      if @context.exists? then
         @types[:all] = Type.new(self, :all, nil)
         @dsl.instance_eval do
            define_type_constraint :length, Types::TextType   , TypeConstraints::LengthConstraint
            define_type_constraint :length, Types::BinaryType , TypeConstraints::LengthConstraint
            define_type_constraint :range , Types::NumericType, TypeConstraints::RangeConstraint
            define_type_constraint :check , Type              , TypeConstraints::CheckConstraint
      
            define_type :any       , :all
            define_type :void      , :all
                             
            define_type :binary    , :any    , Types::BinaryType    
            define_type :text      , :any    , Types::TextType    
            define_type :real      , :any    , Types::NumericType    
            define_type :integer   , :real   , Types::IntegerType    
            define_type :boolean   , :integer, Types::IntegerType, :range => 0..1
            define_type :datetime  , :text   , Types::DateTimeType
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
      end
      
      @dsl.instance_eval(&block) if block_given?
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
         assert( !@schema.entities.member?(name), "duplicate entity name", {"name" => name} )
         assert( parent.nil? || @schema.entities.member?(parent), "parent not defined", {"name" => parent} )
         @schema.entities[name] = Entity.new( self, name, parent.nil? ? nil : @schema.entities[parent], &block )      
      end
   
   
      #
      # Defines a simple (non-entity) type.  
   
      def define_type( name, base_type = nil, *type_class_and_constraints )
         type_check( name, [Symbol, Class] )
      
         type_class  = type_class_and_constraints.first.is_a?(Class) ? type_class_and_constraints.shift : Type
         constraints = type_class_and_constraints.first.is_a?(Hash)  ? type_class_and_constraints.shift : {}

         return @schema.build_type( base_type, constraints, name, type_class )
      end
   
   
      #
      # Associates a type constraint with a trigger for use in declarations.
   
      def define_type_constraint( trigger, for_type, constraint_class )
         @schema.constraint_templates[trigger] = {} unless @schema.constraint_templates.member?(trigger)
         @schema.constraint_templates[trigger][for_type] = constraint_class
      end
   end
   
   
   
   # ==========================================================================================
   #                                      Public Interface
   # ==========================================================================================
   
   
   attr_reader :name, :source, :entities, :constraint_templates
   

   #
   # Creates or returns a type based on your description.  If you pass a new_name, you are 
   # guaranteed to get a new type object, and it will be registered for you.  Raises an 
   # exception if the base type is not found, or if the new_name is already taken.  Removes
   # Removes any used modifiers.
   
   def build_type( from, modifiers, as_name = nil, type_class = Type )
      type_check( from, [Symbol, Class, Type] )
      type_check( as_name, [Symbol, Class], true )

      base_type = find_type(from)
      
      #
      # Process any constraints from the modifiers list.
      
      constraints = []
      modifiers.each do |name, value|
         if constraint = build_constraint( name, value, base_type ) then
            constraints << constraint
            modifiers.delete(name)
         end
      end

      #
      # Build and name a new type, if necessary, and return.
      
      if as_name.is_a?(Class) then
         type = Types::MappedType.new( self, as_name, base_type, modifiers.fetch(:store, nil), modifiers.fetch(:load, nil) )
      elsif constraints.exist? or as_name.exists? then
         type = type_class.new( self, as_name, base_type, constraints )
      end
         
      if as_name.exists? then
         assert( !@types.member?(as_name), "new type name [#{as_name}] is already defined" )
         @types[as_name] = type 
      end

      return type
   end
   
   
   #
   # Builds a contraint from pieces.

   def build_constraint( trigger, value, type )
      @constraint_templates[trigger].each do |trigger_class, constraint_class|
         type.each_effective_type do |current|
            if current.class.ancestors.member?(trigger_class) then
               return constraint_class.new(value) 
            end
         end
      end
      
      return nil
   end
   
   
   #
   # Register a named object with the schema.
   
   def register( object )
      assert( !@object.member?(object.fqn), "object [#{object.fqn}] already registered" )
      @objects[object.fqn] = object
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
            break if type = type(current, false, true)
         end
      else
         if @types.member?(name) then
            type = @types[name]
         elsif @context.exists? then
            type = @context.type(name, false, true)
         end
      end   

      if fail_if_missing then
         assert( type.exists?, name.is_a?(Symbol) ? "unrecognized type [#{name}]" : "no type mapping for class [#{from.name}]" )
      end
      
      return type
   end
   
   
   
   



protected

   # ==========================================================================================
   #                                          Internals
   # ==========================================================================================


   


   #
   # Brings the database structures up to match the current schema.
   
   def update_database_structures()
      # @@monitor.synchronize do
      #    if @connection.tables.exists? then
      #       if @connection.tables.member?()
      #    end
      # end
   end
   
   
   
end # Schema
end # Model
end # Schemaform


require Schemaform.locate("type.rb"           ) 
require Schemaform.locate("type_constraint.rb")
require Schemaform.locate("entity.rb"         )

require 'rubygems'
require 'sequel'

