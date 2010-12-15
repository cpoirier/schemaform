#!/usr/bin/env ruby -KU
# =============================================================================================
# SchemaForm
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
# Provides a naming context and a unit of storage within the SchemaForm system.  Multiple
# Schemas can coexist within one physical database, but names are unique.

module SchemaForm
module Model
class Schema
   
   #
   # Defines a schema and calls your block to fill it in.  With this method, your
   # block can treat the Schema interface as a DSL.
   
   def self.define( name, &block )
      @@monitor.synchronize do
         if @@schemas.member?(name) then
            raise AssertionFailure.new("duplicate schema name", {"name" => name, "existing" => @@schemas[name].source})
         end
         
         @@schemas[name] = self.new( name, caller()[0], &block )
      end
   end
   
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
      
   attr_reader :name, :source
   
   #
   # Defines an entity within the Schema.
   
   def define( name, parent = nil, &block )
      assert( !@entities.member?(name), "duplicate entity name", {"name" => name} )
      assert( parent.nil? || @entities.member?(parent), "parent not defined", {"name" => parent} )
      @entities[name] = Entity.new( self, name, parent.nil? ? nil : @entities[parent], &block )      
   end
   
   
   #
   # Defines a mapping from Ruby to SchemaForm types, and how to convert from one to 
   # the other.  When defining fields, you may use either expression, and the mappings
   # will be used to determine the other type.  All parameters are supplied as pairs.  
   # The only required one is from Ruby class to SchemaForm type.  You can additionally
   # override the default conversion routines by providing :write (Ruby => SchemaForm)
   # and :read (SchemaForm => Ruby) procs.
   #
   # Example:
   #   map IPAddr => :text, :length => 40, :write => :to_s, :read => lambda {|v| SHA1.new(v)}
      
   def map( data )
      
      #
      # Parse the parameter data.
      
      modifiers = {}
      ruby_type = sf_type = writer = reader = nil
      data.each do |key, value|
         case key
         when Class
            ruby_type = key
            sf_type   = value
         when :read
            reader = value
         when :write
            writer = value
         else
            modifiers[key] = value
         end
      end
      
      #
      # Build a base SchemaForm type that contains all modifiers.
      
      assert( ruby_type.exists? && sf_type.is_a?(Symbol), "expected a mapping from a Ruby Class to a SchemaForm type" )
      base_type = build_type( sf_type, modifiers )
      
      #
      # Build a MappedType on the base type and save it.
      
      mapping = Types::MappedType.new( self, ruby_type, base_type, writer, reader )
      
      @mappings_by_ruby_type[ruby_type] = {} unless @mappings_by_ruby_type.member?(ruby_type)
      @mappings_by_sf_type[sf_type]     = {} unless @mappings_by_sf_type.member?(sf_type)
      
      assert( !@mappings_by_ruby_type[ruby_type].member?(sf_type), "type mapping from Ruby type #{ruby_type} to Schema type #{sf_type} already defined" )
      assert( !@mappings_by_sf_type[sf_type].member?(ruby_type)  , "type mapping from Schema type #{sf_type} to Ruby type #{ruby_type} already defined" )

      @mappings_by_ruby_type[ruby_type][sf_type] = mapping
      @mappings_by_sf_type[sf_type][ruby_type]   = mapping
      
   end
   
   
   #
   # Defines a simple (non-entity) type.  
   
   def define_type( name, base_type = nil, *type_class_and_constraints )
      
      type_class  = type_class_and_constraints.first.is_a?(Type) ? type_class_and_constraints.shift : Type
      constraints = type_class_and_constraints.first.is_a?(Hash) ? type_class_and_constraints.shift : {}

      type = build_type( base_type, constraints, name, type_class )

      return type
   end
   
   
   #
   # Associates a type constraint with a trigger for use in declarations.
   
   def define_type_constraint( trigger, for_type, constraint_class )
      @constraint_templates[trigger] = {} unless @constraint_templates.member?(trigger)
      @constraint_templates[trigger][for_type] = constraint_class
   end
   
   
   
   



protected

   # ==========================================================================================
   #                                          Internals
   # ==========================================================================================

   @@monitor = Monitor.new()
   @@schemas = {}
   
   def initialize( name, source, &block )
      @name     = name
      @source   = source
      @entities = {}
      @types    = { :all => Type.new(self, :all, nil) }
      
      @constraint_templates  = {}
      @mappings_by_ruby_type = {}
      @mappings_by_sf_type   = {}
      
      define_type_constraint :length, Types::TextType   , TypeConstraints::CharacterLengthConstraint
      define_type_constraint :length, Types::BinaryType , TypeConstraints::ByteLengthConstraint
      define_type_constraint :range , Types::NumericType, TypeConstraints::RangeConstraint
      define_type_constraint :check , Type              , TypeConstraints::CheckConstraint
      

      define_type :any     , :all
      define_type :void    , :all

      define_type :binary  , :any    , Types::BinaryType    
      define_type :text    , :any    , Types::TextType    
      define_type :real    , :any    , Types::NumericType    
      define_type :integer , :real   , Types::IntegerType    
      define_type :boolean , :integer, Types::IntegerType, :range => 0..1
      define_type :datetime, :text   , Types::DateTimeType
      
      map String     => :text
      map IPAddr     => :text, :length => 40
      map TrueClass  => :boolean, :write => lambda { 1 }, :read => lambda {|v| v == 1 ? true : false}
      map FalseClass => :boolean, :write => lambda { 0 }, :read => lambda {|v| v == 1 ? true : false}
      map Time       => :datetime, 
                        :write => lambda {|t| utc = t.getutc; utc.strftime("%Y-%m-%d %H:%M:%S") + (utc.usec > 0 ? ".#{utc.usec}" : "") },
                        :read  => lambda {|s| year, month, day, hour, minute, second, micros = *s.split(/[:\-\.] /); Time.utc(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i, second.to_i, micros.to_i)}
              
      instance_eval(&block) if block_given?
   end
   

   #
   # Creates or returns a type based on your description.  If you pass a new_name, you are 
   # guaranteed to get a new type object, and it will be registered for you.  Raises an 
   # exception if the base type is not found, or if the new_name is already taken.  Removes
   # Removes any used modifiers.
   
   def build_type( from, modifiers, as_name = nil, type_class = Type )
      type_check( from, [Symbol, Class, Type] )
      
      #
      # First, figure out the base Type.

      base_type = nil

      if from.is_a?(Symbol) then
         assert( @types.member?(from), "unrecognized type [#{from}]" )
         base_type = @types[from]
      elsif from.is_a?(Class) then
         from.ancestors.each do |current|
            if @mappings_by_ruby_type.member?(current) then
               base_type = @mappings_by_ruby_type[current].first
               break
            end
         end
         assert( base_type.exists?, "no type mapping for class [#{from.name}]" )
      else
         base_type = from
      end
      
      type = base_type
      
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
      
      if constraints.exist? or as_name.exists? then
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
   
   
   
   
end # Schema
end # Model
end # SchemaForm


require $schemaform.local_path("type.rb"           ) 
require $schemaform.local_path("type_constraint.rb")
require $schemaform.local_path("entity.rb"         )

