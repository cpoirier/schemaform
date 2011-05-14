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

require Schemaform.locate("schemaform/schema.rb")

module Schemaform
module Language
class TupleDefinition
   include QualityAssurance
   
   def self.build( context, name = nil, register = false, &block )
      Schema::Tuple.new(context, name).tap do |tuple|
         context.schema.tuples.register(tuple) if register
         TupleDefinition.process(tuple, &block)
      end      
   end
   
   def self.process( tuple, &block )
      dsl = new(tuple)
      dsl.instance_eval(&block)
      tuple
   end

   def initialize( tuple )
      @tuple  = tuple
      @schema = tuple.schema
   end
   
   
   #
   # Imports (and potentially redefines) attributes from another tuple type.  Redefinitions
   # are provided as a block to the import command.
   
   def import( tuple_name, &block )
      imported_tuple = @schema.tuples.find(tuple_name)
      redefinitions  = block ? self.class.build(@schema, &block) : nil
      
      imported_tuple.recreate_children_in(@tuple, redefinitions)
   end


   #
   # Defines a required attribute or subtuple within the entity.  To define a subtuple, supply a 
   # block instead of a type.

   def required( name, type_name = nil, modifiers = {}, &block )
      definition = definition_for(type_name, modifiers, name, &block)
      @tuple.attributes.register(Schema::RequiredAttribute.new(name, @tuple, definition))
   end

   
   #
   # Defines an optional attribute or subtuple within the entity.  To define a subtuple, supply
   # a block instead of a type.
   
   def optional( name, type_name = nil, modifiers = {}, &block )
      definition = definition_for(type_name, modifiers, name, &block)
      @tuple.attributes.register(Schema::OptionalAttribute.new(name, @tuple, definition))
   end
   
      
   #
   # Defines a static attribute within the tuple. A static attribute is filled once when
   # the tuple is created, and thereafter only if you update one of its roots within the
   # tuple itself.

   def static( name, *args, &block )
      derived(name, Schema::StaticAttribute, *args, &block)
   end   
   
   
   #
   # Defines a maintained attribute within the tuple. A maintained attribute is kept
   # up to date for you by the system, and you can rely on it being up to date at the
   # end of every transaction. Supply a Proc or a block.  

   def maintained( name, *args, &block )
      derived(name, Schema::MaintainedAttribute, *args, &block)
   end   
   
   
   #
   # Defines a volatile attribute within the tuple. A volatile attribute is calculated
   # on every use (it is never stored in the database). Be careful with this: too much
   # complexity in a volatile attribute will mean all processing must be moved into
   # Ruby memory, and that can be very expensive. 

   def volatile( name, *args, &block )
      derived(name, Schema::VolatileAttribute, *args, &block)
   end   
   
   
   #
   # Defines a constraint on the tuple that will be checked on save.
   
   def constrain( description, proc = nil, &block )
      warn_once("TODO: constraint support in Tuple")
   end
   
   
   #
   # Creates a Reference for use as an attribute definition.
   
   def member_of( entity_name )
      type_check(:entity_name, entity_name, Symbol)
      Schema::Reference.new(entity_name, @tuple)
   end
   
   
   #
   # Creates a Set or Relation for use as an attribute definition.
   
   def set_of( type_name, modifiers = {} )
      collection_of(type_name, modifiers, Schema::Relation, Schema::Set)
   end

   
   #
   # Creates an (ordered) list for use as an attribute definition.
   
   def list_of( type_name, modifiers = {} )
      collection_of(type_name, modifiers, Schema::Tabulation, Schema::List)
   end
   
   
   #
   # Creates a coded or enumerated type for use as an attribute definition.
   
   def one_of( *values )
      if values.length == 1 && values[0].is_a?(Hash) then
         Schema::Scalar.new(Schema::CodedType.new(values[0], :context => @tuple))
      else
         Schema::Scalar.new(Schema::EnumeratedType.new(values, :context => @tuple))
      end
   end
   
   
private

   #
   # Creates a derived field of the appropriate class.
   
   def derived( name, clas, *args, &block )
      modifiers = args.first.is_a?(Hash) ? args.shift : {}
      proc      = block || args.shift
      formula   = Schema::Formula.new(proc, @tuple, @tuple.root_tuple)

      @tuple.attributes.register(clas.new(name, @tuple, formula))
   end
   
   
   #
   # Creates a collection of the appropriate class.
   
   def collection_of( type_name, modifiers = {}, complex_class = Schema::Relation, simple_class = Schema::Set )
      warn_once("consider modifiers on a collection_of")

      if @schema.tuples.member?(type_name) then
         complex_class.new(@schema.tuples[type_name])
      elsif @schema.types.member?(type_name) then
         simple_class.new(type_for(type_name, modifiers))
      else
         simple_class.new(Schema::Reference.new(type_name, @tuple))
      end      
   end
   
   
   #
   # Retrieves or builds a definition for the given name.
   
   def definition_for( name, modifiers, implied_name = nil, &block )
      return name if name.is_an?(Schema::Element)
      
      if block then
         TupleDefinition.build(@tuple, implied_name, &block)
      elsif @schema.types.member?(name) then
         Schema::Scalar.new(@schema.types.build(name, modifiers))         
      elsif @schema.tuples.member?(name) then
         @schema.tuples.find(name)
      else
         member_of(name)
      end
   end
   
   
end # TupleDefinition
end # Language
end # Schemaform