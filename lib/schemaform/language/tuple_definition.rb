#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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
   
   def self.build( name = nil, register = true, &block )
      Schema::Tuple.new(name).tap do |tuple|
         Schema.current.register_tuple(tuple) if name && register
         TupleDefinition.process(tuple, &block)
      end      
   end
   
   def self.process( tuple, &block )
      tuple.tap do 
         dsl = new(tuple)
         dsl.instance_eval(&block)
      end
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
      redefinitions  = block ? self.class.build(nil, false, &block) : nil
      redefinitions  = nil if redefinitions && redefinitions.empty?
      
      imported_tuple.recreate_children_in(@tuple, redefinitions)
   end


   #
   # Defines a required attribute or subtuple within the entity. To define a subtuple, supply a 
   # block instead of a type.

   def required( name, type_name = nil, modifiers = {}, &block )
      @tuple.register Schema::RequiredAttribute.new(name, type_for(type_name, modifiers, name, &block))
   end

   
   #
   # Defines an optional attribute or subtuple within the entity. To define a subtuple, supply
   # a block instead of a type. 
   #
   # Optional attributes have a default value that will be used if no value is supplied. This is 
   # optional value is generally supplied via the :default modifier, and can be a static value
   # or a formula by which a static value will be calculated (when the tuple is created or when 
   # an existing value for the attribute is cleared).
   #
   # As a convenience, as long as you are not supplying a subtuple, you can supply a Proc (not a 
   # block) in place of the type_name, which will be used as the default, with the attribute type 
   # inferred from the formula.
   
   def optional( name, type_name = nil, modifiers = {}, &block )
      if type_name.is_a?(Proc) then
         assert(block.nil?, "please use the formal syntax for default if you are defining a subtuple")
         @tuple.register Schema::OptionalAttribute.new(name, nil, type_name)
      else
         @tuple.register Schema::OptionalAttribute.new(name, type_for(type_name, modifiers, name, &block))
      end
   end
   
      
   #
   # Defines a derived attribute within the tuple. A derived attribute is kept
   # up to date for you by the system, and you can rely on it being up to date at the
   # end of every transaction. Supply a Proc or a block.  

   def derived( name, *args, &block )
      modifiers = args.first.is_a?(Hash) ? args.shift : {}
      proc      = block || args.shift

      @tuple.register Schema::DerivedAttribute.new(name, proc)
   end   
   

   #
   # Defines a constraint on the tuple that will be checked on save.
   
   def constrain( description, proc = nil, &block )
      warn_todo("constraint support in Tuple")
   end
   
   
   #
   # Creates a Reference for use as an attribute definition.
   
   def member_of( entity_name )
      type_check(:entity_name, entity_name, Symbol)
      Schema::EntityReferenceType.new(entity_name)
   end
   
   
   #
   # Creates a Set or Relation for use as an attribute definition.
   
   def set_of( type_name, modifiers = {} )
      Schema::SetType.build(type_for(type_name, modifiers))
   end

   
   #
   # Creates an (ordered) list for use as an attribute definition.
   
   def list_of( type_name, modifiers = {} )
      Schema::ListType.build(type_for(type_name, modifiers))
   end
   
   
   #
   # Creates a coded or enumerated type for use as an attribute definition.
   
   def one_of( *values )
      if values.length == 1 && values[0].is_a?(Hash) then
         Schema::CodedType.new(values[0])
      else
         Schema::EnumeratedType.new(values)
      end
   end
   
   
private

   #
   # Retrieves or builds a definition for the given name.
   
   def type_for( name, modifiers, implied_name = nil, &block )
      return name if name.is_a?(Schema::Type)
      
      if block then
         Schema::TupleType.new(TupleDefinition.build(&block))
      elsif @schema.types.member?(name) then
         @schema.types.build(name, modifiers)
      elsif @schema.tuples.member?(name) then
         Schema::TupleType.new(@schema.tuples.find(name))
      else
         member_of(name)
      end
   end
   
   
end # TupleDefinition
end # Language
end # Schemaform