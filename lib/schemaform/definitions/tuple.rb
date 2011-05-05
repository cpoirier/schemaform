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

require Schemaform.locate("thing.rb")
require Schemaform.locate("types/structured_type.rb")
require Schemaform.locate("expression_result.rb")


#
# A description of a single tuple (or "record") of data.  

module Schemaform
module Definitions
class Tuple < Thing

   def initialize( context, name = nil, &block )
      super(context, name)
      
      @attributes = {}
      @expression = nil
      @definer    = DefinitionLanguage.new(self)
      @variable   = TupleVariable.new(self)

      @type = StructuredType.new(:context => self) do |name|
         @attributes[name].resolve
      end

      define(&block) if block_given?
   end
   
   attr_reader :attributes, :definer, :type
   
   def []( name )
      @attributes[name]
   end
   
   def default()
      return @default unless @default.nil?
      @default = {}.tap do |pairs|
         each_attribute do |attribute|
            if attribute.writable? then
               pairs[attribute.name] = attribute.resolve.default
            end
         end
      end
   end
   
   def description()
      @type.description
   end
   
   def root_tuple()
      return context.root_tuple if context.responds_to?(:root_tuple)
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
      include QualityAssurance
      
      def initialize( tuple )
         @tuple = tuple
      end
      
      
      #
      # Imports (and potentially redefines) attributes from another tuple type.  Redefinitions
      # are provided as a block to the import command.
      
      def import( name, &block )

         imported_type = @tuple.schema.tuples.find( name )
         redefinitions = Tuple.new( @tuple, &block )
         
         check do
            redefinitions.each_attribute do |attribute|
               assert( imported_type.member?(attribute.name), "can't redefine attribute [#{attribute.name}], as it does not exist in the imported tuple [#{imported_type.full_name}]" )
            end
         end
         
         @tuple.instance_eval do
            imported_type.each_attribute do |attribute|
               new_attribute = if redefinitions.member?(attribute.name) then
                  redefinitions.attributes[attribute.name].recreate_in( self )
               else
                  attribute.recreate_in( self )
               end
               add_attribute attribute.name, new_attribute
            end
         end
      end

   
      #
      # Defines a required attribute or subtuple within the entity.  To define a subtuple, supply a 
      # block instead of a type.
   
      def required( name, type_name = nil, modifiers = {}, &block )
         definition = definition_for(type_name, modifiers, &block)
         @tuple.instance_eval do
            add_attribute name, RequiredAttribute.new(self, definition)
         end
      end

      
      #
      # Defines an optional attribute or subtuple within the entity.  To define a subtuple, supply
      # a block instead of a type.
      
      def optional( name, type_name = nil, modifiers = {}, &block )
         definition = definition_for(type_name, modifiers, &block)
         @tuple.instance_eval do
            add_attribute name, OptionalAttribute.new(self, definition)
         end
      end
      
         
      #
      # Defines a static attribute within the tuple. A static attribute is filled once when
      # the tuple is created, and thereafter only if you update one of its roots within the
      # tuple itself.
   
      def static( name, *args, &block )
         derived(name, StaticAttribute, *args, &block)
      end   
      
      
      #
      # Defines a maintained attribute within the tuple. A maintained attribute is kept
      # up to date for you by the system, and you can rely on it being up to date at the
      # end of every transaction. Supply a Proc or a block.  
   
      def maintained( name, *args, &block )
         derived(name, MaintainedAttribute, *args, &block)
      end   
      
      
      #
      # Defines a volatile attribute within the tuple. A volatile attribute is calculated
      # on every use (it is never stored in the database). Be careful with this: too much
      # complexity in a volatile attribute will mean all processing must be moved into
      # Ruby memory, and that can be very expensive. 
   
      def volatile( name, *args, &block )
         derived(name, VolatileAttribute, *args, &block)
      end   
      
      
      #
      # Defines a constraint on the tuple that will be checked on save.
      
      def constrain( description, proc = nil, &block )
         warn_once("TODO: constraint support in Tuple")
      end
      
      
      #
      # Creates a reference type.
      
      def member_of( entity_name )
         Scalar.new(ReferenceType.new(entity_name, :context => @tuple.schema))
      end
      
      
      #
      # Creates a set type.
      
      def set_of( type_name, modifiers = {} )
         Set.new(definition_for(type_name, modifiers), @tuple)
      end
      
      #
      # Create an (ordered) list type.
      
      def list_of( type_name, modifiers = {} )
         List.new(definition_for(type_name, modifiers), @tuple)
      end
      
      
      #
      # Creates a coded or enumerated type.
      
      def one_of( *values )
         if values.length == 1 && values[0].is_a?(Hash) then
            Scalar.new(CodedType.new(values[0], :context => @tuple))
         else
            Scalar.new(EnumeratedType.new(values, :context => @tuple))
         end
      end
      
      
   private
   
      #
      # Creates a derived field of the appropriate class.
      
      def derived( name, clas, *args, &block )
         modifiers = args.first.is_a?(Hash) ? args.shift : {}
         proc      = block || args.shift
         formula   = Formula.new(proc, modifiers, @tuple){|body, production| body.call(@tuple.root_tuple.variable(production))}

         @tuple.instance_eval do
            add_attribute name, clas.new(self, formula)
         end
      end
      
   
      #
      # Used to process an attribute definition into a Definition.

      def definition_for( name, modifiers, &block )
         if name.is_a?(Thing) then
            return name
         elsif block then
            Tuple.new(@tuple, nil, &block)
         elsif name.is_a?(Hash) then
            one_of(name)
         elsif name.is_an?(Array) then
            one_of(*name)
         elsif @tuple.schema.types.member?(name) then
            Scalar.new(@tuple.schema.types.build(name, modifiers), @tuple)
         elsif @tuple.schema.tuples.member?(name) then
            @tuple.schema.tuples.find(name)
         else
            Reference.new(ReferenceType.new(name, :context => @tuple.schema), @tuple)
         end
      end
      
   end
   
   
   
   
   # ==========================================================================================
   #                                     Expression Interface
   # ==========================================================================================
   
   class TupleVariable < ExpressionResult

      def initialize( definition, production = nil )
         super(definition, production)
      end

      def method_missing( symbol, *args, &block )
         return super unless @definition.member?(symbol)
         @definition[symbol].variable(Expressions::Accessor.new(self, symbol))
      end
      
   end # TupleVariable
   
   
   def variable( production = nil )
      production.nil? ? @variable : TupleVariable.new(self, production)
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
         assert( !@attributes.member?(name), "a TupleType cannot contain two attributes with the same name [#{name}]"    )
      end
      
      @type.register(name)
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

   def dereference( lh_expression, rh_symbol )
      if @attributes.member?(rh_symbol) then
         Expressions::DottedExpression.new(lh_expression, rh_symbol, @attributes[rh_symbol].type) 
      else
         nil
      end
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
   


   
   

end # Type
end # Definitions
end # Schemaform

