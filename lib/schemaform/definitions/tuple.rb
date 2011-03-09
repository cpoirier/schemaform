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


#
# A description of a single tuple (or "row") of data.  

module Schemaform
module Definitions
class Tuple < Type
   
   def initialize( context, type_name = nil, extends = nil, loader = nil, storer = nil, &block )
      super( context, type_name.nil? ? false : type_name )
      
      warn_once( "base type and modifiers not yet supported for Tuple types" )
      
      @attributes = {}                       
      @expression = Expressions::Tuple.new(self)
      @closed     = false
      @definer    = DefinitionLanguage.new(self)

      define(&block) if block_given?
   end
   
   attr_reader :expression, :root_tuple, :attributes, :definer
   
   def default()
      return @default unless @default.nil?
      @default = {}.tap do |pairs|
         each_attribute do |attribute|
            if attribute.writable? then
               pairs[attribute.name] = attribute.resolve(TypeInfo::SCALAR).default
            end
         end
      end
   end
   
   def type_info()
      TypeInfo::TUPLE
   end
   
   def description()
      pairs = @attributes.collect{|name, attribute| ":" + name.to_s + " => " + attribute.resolve().description}
      "{" + pairs.join(", ") + "}"
   end

   def root_tuple()
      return context.tuple.root_tuple if context.is_a?(Attribute)
      return self
   end
   
   def define( name = nil, &block )
      self.name = name if name      
      @definer.instance_eval( &block )
   end
   
   def each_attribute()
      @attributes.each do |name, attribute|
         yield( attribute )
      end
   end
   
   def member?( name )
      name = name.name if name.is_an?(Attribute)
      @attributes.member?(name)
   end   
   
   def width()
      @attributes.length
   end   
      
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   
   class DefinitionLanguage
      def initialize( tuple )
         @tuple = tuple
      end

   
      #
      # Defines a required attribute or subtuple within the entity.  To define a subtuple, supply a 
      # block instead of a type.
   
      def required( name, base_type = nil, modifiers = {}, required = true, &block )
         attribute_class = required ? RequiredAttribute : OptionalAttribute         
         @tuple.instance_eval do
            attribute = add_attribute( name, attribute_class.new(self) )
            if block_given? then
               assert( (type_name = base_type).exists?, "please name the tuple type for attribute [#{name}]" )
               attribute.type = Tuple.new( attribute, type_name, modifiers.delete(:extends), modifiers.delete(:load), modifiers.delete(:store), &block )
            else
               assert( base_type.exists?, "expected type for attribute [#{name}]")
               attribute.type = TypeReference.build( attribute, base_type, modifiers )
            end
         end
      end

      
      #
      # Defines an optional attribute or subtuple within the entity.  To define a subtuple, supply
      # a block instead of a type.
      
      def optional( name, base_type = nil, modifiers = {}, &block )
         required name, base_type, modifiers, false, &block
      end
      
         
      #
      # Defines a derived attribute within the entity.  Supply a Proc or a block.  
   
      def cached( name, proc = nil, &block )
         @tuple.instance_eval do
            check { assert(proc.nil? ^ block.nil?, "expected a Proc or block") }
            add_attribute name, CachedAttribute.new(self, proc.nil? ? block : proc)
         end
      end   
      
      
      #
      # Defines a derived attribute within the entity.  Supply a Proc or a block.  
   
      def maintained( name, proc = nil, &block )
         @tuple.instance_eval do
            check { assert(proc.nil? ^ block.nil?, "expected a Proc or block") }
            add_attribute name, MaintainedAttribute.new(self, proc.nil? ? block : proc)
         end
      end   
      
      
      #
      # Defines a derived attribute within the entity.  Supply a Proc or a block.  
   
      def volatile( name, proc = nil, &block )
         @tuple.instance_eval do
            check { assert(proc.nil? ^ block.nil?, "expected a Proc or block") }
            add_attribute name, VolatileAttribute.new(self, proc.nil? ? block : proc)
         end
      end   
      
      
      #
      # Creates a reference type.
      
      def member_of( entity_name )
         TypeReference.new( @tuple, entity_name, {}, :entity )
      end
      
      
      #
      # Creates a set
      
      def set_of( type_name, modifiers = {} )
         SetType.new( TypeReference.build(@tuple, type_name, modifiers, :scalar), @tuple.schema )
      end
   end
   
   
   
   # ==========================================================================================
   #                                          Operations
   # ==========================================================================================
   
   
   def each_attribute()
      @attributes.each do |name, attribute|
         yield( attribute )
      end
   end
   
   def add_attribute( name, attribute )
      check do
         assert( !@closed              , "attributes cannot be added to a Tuple after type resolution has begun" )
         assert( !@attributes.member?(name), "a Tuple cannot contain two attributes with the same name [#{name}]"    )
      end
      
      @attributes[name] = attribute
      attribute.name = name unless attribute.named?
      attribute
   end

   def attribute?( name )
      @attributes.member?(name)
   end
   
   def empty?()
      @attributes.empty?
   end
   
   def length()
      @attributes.count
   end


   
   # ==========================================================================================
   #                                       Type Operations
   # ==========================================================================================

   def resolve( preferred = nil )
      unless @closed
         @closed = true
         supervisor.monitor(self, named?) do
            each_attribute do |attribute|
               attribute.resolve( preferred )
            end
            self
         end
      end
      
      self
   end
   
   
   # ==========================================================================================
   #                                           Conversion
   # ==========================================================================================


   def lay_out( builder, &attribute_condition )
      builder.in_tuple_class( @name ) do
         each_attribute do |attribute|
            if attribute_condition.nil? || attribute_condition.call(attribute) then 
               attribute.lay_out( builder )
            end
         end
      end
   end
   


   
   

end # Tuple
end # Definitions
end # Schemaform

require Schemaform.locate("attribute.rb")
require Schemaform.locate("schemaform/expressions/tuple.rb")
