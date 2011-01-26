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
   
   def initialize( schema, naming_context = nil, &block )
      super( schema )
      @naming_context = naming_context || self   # Where we get the tuple expression when resolving fields
      @fields         = {}                       # name => Formula
      @expression     = Expressions::Tuple.new(self)
      @closed         = false
      
      DefinitionLanguage.new(self).instance_eval(&block) if block_given?
   end
   
   attr_reader :naming_context, :expression

   def dimensionality()
      1
   end
      
      
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   
   class DefinitionLanguage
      def initialize( tuple, schema = nil )
         @tuple  = tuple
         @schema = schema || @tuple.schema
      end
      
   
      #
      # Defines a required field or subtuple within the entity.  To define a subtuple, supply a 
      # block instead of a type.
   
      def required( name, base_type = nil, modifiers = {}, required = true, &block )
         field_class = required ? FieldTypes::RequiredField : FieldTypes::OptionalField
         @tuple.instance_eval do
            if block_given? then
               check { assert(base_type.nil?, "specify either a type or a block, not both") }
               subtuple = Tuple.new( @schema, @naming_context, &block )
               add_field name, field_class.new(self, subtuple)
            else
               add_field name, field_class.new(self, TypeReference.new(@schema, base_type, modifiers))
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
            add_field name, FieldTypes::DerivedField.new(self, proc.nil? ? block : proc)
         end
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
      field.name = name
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

   def resolve( supervisor )
      unless @closed
         @closed = true
         supervisor.monitor(self, path()) do
            each_field do |field|
               field.resolve( supervisor )
            end
         end
      end
      
      self
   end
   

end # Tuple
end # Definitions
end # Schemaform

require Schemaform.locate("field.rb")
require Schemaform.locate("schemaform/expressions/tuple.rb")
