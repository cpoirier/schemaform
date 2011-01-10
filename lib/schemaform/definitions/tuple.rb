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
class Tuple < Base
   
   def initialize( schema, naming_context = nil )
      super( schema )
      @context = naming_context
      @fields  = {}
      @type    = nil
   end
   
   def name()
      return @context.name if @context.exists?
      return nil
   end
   
   def path()
      return @context.path if @context.exists?
      return []
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
         @tuple.instance_eval do
            if block_given? then
               check { assert(base_type.nil?, "specify either a type or a block, not both") }
               add_field Fields::TupleField.new(self, name, &block)
            else
               field_type = Types::ScalarType.new( base_type, modifiers, @schema )
               add_field Fields::StoredField.new(self, name, field_type, required)
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
            add_field Fields::DerivedField.new(self, name, proc.nil? ? block : proc)
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
   
   def add_field( field )
      check do
         assert( @type.nil?, "fields cannot be added to a Tuple after its type has been resolved" )
         assert( !@fields.member?(field.name), "a Tuple cannot contain two fields with the same name [#{field.name}]" )
      end
      
      @fields[field.name] = field
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
   
   
   def resolve_types( resolution_path = [], tuple_expression = nil )
      tuple_expression = Expressions::Tuple.new(self) if tuple_expression.nil?
      @fields.each do |name, field|
         field.resolve_type( resolution_path, tuple_expression )
         puts "#{field.path.join(".")}: #{field.type.description}" if field.type.exists?
      end
   end
   

end # Tuple
end # Definitions
end # Schemaform

require Schemaform.locate("field.rb")
require Schemaform.locate("schemaform/expressions/tuple.rb")
