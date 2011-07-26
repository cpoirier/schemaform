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
Dir[Schemaform.locate("expression_capture/*.rb")].each{|path| require path}

module Schemaform
module Language
module ExpressionCapture
   extend QualityAssurance
   
   def self.resolution_scope( schema )
      Thread[:expression_contexts] = [] unless Thread.key?(:expression_contexts)
      Thread[:expression_contexts].push_and_pop(schema) do
         yield
      end
   end
   
   
   
   def self.merge_types( *from )
      from.inject(resolve_type(:unknown)) do |type, object|
         type.best_common_type(object.type)
      end
   end
   
   def self.unknown_type()
      resolve_type(:unknown)
   end
   
   def self.resolve_type( name )
      return name if name.is_a?(Schema::Type)
      schema = Thread[:expression_contexts].top or fail "ExpressionCapture needs a resolution_scope in place before being able to resolve_type()"
      schema.types.member?(name) ? schema.types[name] : schema.send((name.to_s + "_type").intern)      
   end
   
   def self.capture_type( type, production = nil )
      resolve_type(type).capture(production)
   end
      
   
   def self.capture( value, production = nil )
      case value
      when Value, NilClass
         return value
      when Schema::Type
         return value.capture(production)
      when Array
         return LiteralList.new(*value.collect{|e| capture(e)})
      when Set
         return LiteralSet.new(*value.collect{|e| capture(e)})
      when FalseClass, TrueClass
         return LiteralScalar.new(value, resolve_type(:boolean))
      when Integer
         return LiteralScalar.new(value, resolve_type(:integer))
      when Float
         return LiteralScalar.new(value, resolve_type(:real))
      else
         fail "ExpressionCapture.capture() does not currently handle objects of type #{value.class.name}"
      end
   end
   
   
   def self.capture_method_call(result_type, receiver, method_name, args = [], block = nil )
      capture_type(result_type, Productions::MethodCall.new(receiver, method_name, args, block))
   end
      

   def self.capture_binary_operator( operator, lhs, rhs )
      lhs         = capture(lhs)
      rhs         = capture(rhs)
      result_type = merge_types(lhs.type, rhs.type)
      production  = Productions::BinaryOperator.new(operator, lhs, rhs)
      
      result_type.capture(production)
   end
   
   def self.capture_comparison_operator( operator, lhs, rhs )
      lhs         = capture(lhs)
      rhs         = capture(rhs)
      production  = Productions::ComparisonOperator.new(operator, lhs, rhs)

      resolve_type(:boolean).capture(production)
   end   
   
   def self.capture_logical_and( lhs, rhs )
      boolean = resolve_type(:boolean)
      lhs     = capture(lhs)
      rhs     = capture(rhs)
      assert(boolean.assignable_from?(lhs.type), "expected boolean expression on left-hand of logical and, found #{lhs.type.description}" )
      assert(boolean.assignable_from?(rhs.type), "expected boolean expression on right-hand of logical and, found #{rhs.type.description}")

      boolean.capture(Productions::And.new(lhs, rhs))
   end

   def self.capture_logical_or( lhs, rhs )
      boolean = resolve_type(:boolean)
      lhs     = capture(lhs)
      rhs     = capture(rhs)
      assert(boolean.assignable_from?(lhs.type), "expected boolean expression on left-hand of logical or, found #{lhs.type.description}" )
      assert(boolean.assignable_from?(rhs.type), "expected boolean expression on right-hand of logical or, found #{rhs.type.description}")

      boolean.capture(Productions::Or.new(lhs, rhs))
   end

   def self.capture_expression( formula_context, block, result_type = nil, join_compatible_only = true )
      Language::ExpressionDefinition.module_exec(formula_context, &block).tap do |captured_expression|
         type_check(:captured_expression, captured_expression, Language::ExpressionCapture::Value)
         if result_type then
            if join_compatible_only then
               assert(result_type.join_compatible?(captured_expression.type), "expected expression result to be join compatible with #{result_type.description}, found #{captured_expression.type.description} instead")
            else                                                             
               assert(result_type.assignable_from?(captured_expression.type), "expected expression result to be assignable to #{result_type.description}, found #{captured_expression.type.description} instead")
            end
         end
      end
   end
      
      
   
   
end # ExpressionCapture
end # Language
end # Schemaform





# =============================================================================================
#                                           Value Capture
# =============================================================================================

module Schemaform
class Schema
   
   class Element
      def capture( production = nil )
         fail_unless_overridden self, :capture
      end
      
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :apply
            method, type, *parameters = *args
            parameters = parameters.collect{|p| Language::ExpressionCapture.capture(p)}
            Language::ExpressionCapture.capture_type(type, Productions::Application.new(receiver, method, parameters))
         else
            capture_accessor(receiver, method_name.to_s.tr("!", "").intern)
         end
      end
      
      def capture_accessor( receiver, attribute_name )
         nil
      end
   end   
   
   class Type < Element
      def capture( production = nil )
         Language::ExpressionCapture::Value.new(self, production)
      end      
   end
   
   class UnknownType < Type
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :+, :-, :*, :/, :%
            Language::ExpressionCapture.capture_binary_operator(method_name, receiver, args.shift)
         when :==, :<, :>, :<=, :>=
            Language::ExpressionCapture.capture_comparison_operator(method_name, receiver, args.shift)
         else
            super
         end
      end      
   end
   
   class ScalarType < Type
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :+, :-, :*, :/, :%
            Language::ExpressionCapture.capture_binary_operator(method_name, receiver, args.shift)
         when :==, :<, :>, :<=, :>=
            Language::ExpressionCapture.capture_comparison_operator(method_name, receiver, args.shift)
         else
            super
         end
      end      
   end
   
   class BooleanType < ScalarType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :&
            Language::ExpressionCapture.capture_logical_and(receiver, args.shift)
         when :|
            Language::ExpressionCapture.capture_logical_or(receiver, args.shift)
         else
            super
         end
      end
   end
   
   class NumericType < ScalarType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :floor
            Language::ExpressionCapture.capture_method_call(:integer, receiver, method_name, args, block)
         else
            super
         end
      end
   end
   
   
   class CollectionType < Type
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :+, :-
            Language::ExpressionCapture.capture_binary_operator(method_name, receiver, args.shift)
         when :sum, :average
            check{ assert(!receiver.type.effective_type.member_type.collection_type?, "how do we do aggregation across nested collections?") }
            receiver.type.effective_type.member_type.capture(Productions::Aggregation.new(method_name, receiver))
         when :count
            check{ assert(!receiver.type.effective_type.member_type.collection_type?, "how do we do aggregation across nested collections?") }
            Language::ExpressionCapture.capture_type(:integer, Productions::Aggregation.new(method_name, receiver))
         else
            super
         end
      end

      def capture_accessor( receiver, attribute_name )
         member_type = member_type().evaluated_type
         if member_type.responds_to?(:attribute?) then
            if captured = member_type.capture_method(receiver, attribute_name) then
               return self.class.build(captured.type).capture(Productions::ImpliedContext.new(captured))
            end            
         end
         
         return nil
      end
   end
   
   
   class ListType < CollectionType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :join
            Language::ExpressionCapture.capture_method_call(:text, receiver, method_name, args, block )
         else
            super
         end
      end
   end
   

   class SetType < CollectionType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :order_by
            member_type = member_type().evaluated_type
            if member_type.responds_to?(:attribute?) then
               order_attributes = []
               args.each do |name|
                  ascending = true
                  if name.to_s.ends_with?("!") then
                     ascending = false
                     name = name.to_s.slice(0..-2).intern
                  end

                  if member_type.attribute?(name) then
                     order_attributes << [name, ascending]
                  else
                     check{fail("order-by attribute [#{name}] does not exist")}
                  end
               end

               Schema::ListType.build(member_type).capture(Productions::OrderBy.new(receiver, *order_attributes))
            else
               super
            end
         else 
            super
         end
      end
   end
   
   
   
   class RelationType < SetType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :where
            formula_context     = @tuple_type.formula_context(Productions::ImpliedContext.new(receiver))
            criteria_expression = Language::ExpressionCapture.capture_expression(formula_context, block, schema.boolean_type)
            self.capture(Productions::Restriction.new(receiver, criteria_expression))
         else
            super
         end
      end
   end
   
   
   
   class ReferenceType < Type
      def capture_accessor( receiver, attribute_name )
         return nil unless attribute?(attribute_name)
         
         entity = referenced_entity()
         tuple  = entity.formula_context(Productions::ImpliedContext.new(receiver))
         Language::ExpressionCapture::Attribute.new(entity.heading[attribute_name], Productions::Accessor.new(tuple, attribute_name))
      end
   end
   
   class TupleType < Type
      def formula_context( production = nil )
         @tuple.formula_context(production)
      end
      
      def capture_method( receiver, method_name, args = [], block = nil )
         @tuple.capture_method(receiver, method_name, args, block)
      end
   end
   
   
   class Tuple < Element
      def capture_accessor( receiver, attribute_name )
         return nil unless attribute?(attribute_name)
         Language::ExpressionCapture::Attribute.new(self[attribute_name], Productions::Accessor.new(receiver, attribute_name))
      end
   end
   
   
   

   
   
   class Tuple < Element
      def formula_context( production = nil )
         @formula_context ||= (context.responds_to?(:formula_context) ? context.formula_context : Language::ExpressionCapture::Tuple.new(self, production))
      end      
   end
   
   class Attribute < Element
      def capture( production = nil )
         Language::ExpressionCapture::Attribute.new(self, production)
      end
      
      def formula_context( production = nil )
         context.formula_context(production)
      end
   end
   
   class DerivedAttribute < Attribute
      def type()
         (@type ||= analyze_formula) || schema.unknown_type
      end
      
      def analyze_formula()
         result = nil
         
         unless @analyzing
            debug("processing in #{full_name}")

            Language::ExpressionCapture.resolution_scope(schema) do
               begin
                  @analyzing = true  # Ensure any self-references don't retrigger analysis
                  result = Language::ExpressionCapture.capture_expression(formula_context(), @proc)
               ensure
                  @analyzing = false
               end
            end
         end
         
         if result && !result.type.unknown_type? then
            debug("#{full_name} resolved to #{result.type.description}")
            result.type
         else
            debug("#{full_name} could not be resolved at this time")
            nil
         end
      end
   end
   
   class VolatileAttribute < DerivedAttribute
      
      def type()
         @type ||= capture.type
      end
      
      #
      # Volatile attributes are essentially macros. We treat the formula as if it were used
      # inline in the context. However, to enable that, we disallow recursion.

      def capture( production = nil )
         warn_todo("must recursion be excluded from volatile attributes?")
         
         result = nil
         if @analyzing then
            fail "#{full_name} is a self-referencing volatile attribute, which is not presently supported"
         else
            debug("processing in #{full_name}")
            
            Language::ExpressionCapture.resolution_scope(schema) do
               begin
                  warn_todo("shouldn't the formula_context for a Volatile attribute link in with the context Production?")
                  @analyzing = true  # Set true to ensure any self-references are detected
                  result = Language::ExpressionCapture.capture_expression(formula_context(production), @proc)
               ensure
                  @analyzing = false
               end
            end
         end
         
         return result
      end
   end



   class Entity < Relation
      def formula_context( production = nil )
         warn_once("what does it mean to supply a production to Entity.formula_context()?") if production.nil?
         Language::ExpressionCapture::EntityTuple.new(self, production)
      end
      
      def entity_context( production = nil )
         Language::ExpressionCapture::Entity.new(self, production)
      end
   end
   
   

   
      

end # Schema
end # Schemaform




# =============================================================================================
#                                        Path Discovery
# =============================================================================================

module Schemaform
class Schema

   class Entity < Relation

      #
      # Recurses through the attributes, calling your block at each with the attribute
      # and an expression indicating how it arrived there. When you find what you are 
      # looking for, you can build the final Marker around the path and return (or return 
      # whatever else you want -- we won't judge).

      def search( path = nil, &block )
         unless @heading.attributes.empty?
            path = formula_context() if path.nil?
            @heading.attributes.each do |attribute|
               attribute_path = attribute.capture(path)
               if result = yield(attribute, attribute_path) || attribute.search(attribute_path, &block) then
                  return result
               end
            end
         end
         
         return nil
      end

   end
   
   
   class Tuple < Element
      def search( path = nil, &block )
         unless @attributes.empty?
            path = formula_context() if path.nil?
            @attributes.each do |attribute|
               attribute_path = attribute.capture(path)
               result = yield(attribute, attribute_path) || attribute.search(attribute_path, &block)
               return result if result
            end
         end
         
         return nil
      end
   end
   
   
   class WritableAttribute < Attribute
      def search( path = nil, &block )
         if evaluated_type.is_a?(TupleType) then
            return evaluated_type.tuple.search(path, &block)
         else
            return super
         end
      end
   end
   

   class Element
      def search( path = nil, &block )
         return nil
      end
   end
   
end # Schema
end # Schemaform




