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
      
      @fields     = {}                       
      @expression = Expressions::Tuple.new(self)
      @closed     = false
      @definer    = DefinitionLanguage.new(self)

      define(&block) if block_given?
   end
   
   attr_reader :expression, :root_tuple, :fields, :definer

   def type_info()
      TypeInfo::TUPLE
   end
   
   def description()
      pairs = @fields.collect{|name, field| ":" + name.to_s + " => " + field.resolve().description}
      "{" + pairs.join(", ") + "}"
   end

   def root_tuple()
      return context.tuple.root_tuple if context.is_a?(Field)
      return self
   end
   
   def define( &block )
      @definer.instance_eval( &block )
   end
      
      
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   
   class DefinitionLanguage
      def initialize( tuple )
         @tuple = tuple
      end

   
      #
      # Defines a required field or subtuple within the entity.  To define a subtuple, supply a 
      # block instead of a type.
   
      def required( name, base_type = nil, modifiers = {}, required = true, &block )
         field_class = required ? RequiredField : OptionalField
         @tuple.instance_eval do
            field = add_field( name, field_class.new(self) )
            if block_given? then
               assert( (type_name = base_type).exists?, "please name the tuple type for field [#{name}]" )
               field.type = Tuple.new( field, type_name, modifiers.delete(:extends), modifiers.delete(:load), modifiers.delete(:store), &block )
            else
               assert( base_type.exists?, "expected type for field [#{name}]")
               field.type = TypeReference.build( field, base_type, modifiers )
            end
         end
      end

      
      #
      # Defines an optional field or subtuple within the entity.  To define a subtuple, supply
      # a block instead of a type.
      
      def optional( name, base_type = nil, modifiers = {}, &block )
         required name, base_type, modifiers, false, &block
      end
      
         
      #
      # Defines a derived field within the entity.  Supply a Proc or a block.  
   
      def derived( name, proc = nil, &block )
         @tuple.instance_eval do
            check { assert(proc.nil? ^ block.nil?, "expected a Proc or block") }
            add_field name, DerivedField.new(self, proc.nil? ? block : proc)
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
   
   
   def each_field()
      @fields.each do |name, field|
         yield( field )
      end
   end
   
   def add_field( name, field )
      check do
         assert( !@closed              , "fields cannot be added to a Tuple after type resolution has begun" )
         assert( !@fields.member?(name), "a Tuple cannot contain two fields with the same name [#{name}]"    )
      end
      
      @fields[name] = field
      field.name = name unless field.named?
      field
   end

   def field?( name )
      @fields.member?(name)
   end
   
   def empty?()
      @fields.empty?
   end
   
   def length()
      @fields.count
   end


   
   # ==========================================================================================
   #                                       Type Operations
   # ==========================================================================================

   def resolve()
      unless @closed
         @closed = true
         supervisor.monitor(self, named?) do
            each_field do |field|
               field.resolve()
            end
            self
         end
      end
      
      self
   end
   

end # Tuple
end # Definitions
end # Schemaform

require Schemaform.locate("field.rb")
require Schemaform.locate("schemaform/expressions/tuple.rb")
