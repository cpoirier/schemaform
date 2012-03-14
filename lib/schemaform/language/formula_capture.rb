#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2012 Chris Poirier
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
module FormulaCapture
   extend QualityAssurance
   
   def self.merge_types( *from )
      from.inject(resolve_type(:unknown)) do |merged, current|
         merged.best_common_type(current)
      end
   end
   
   def self.unknown_type()
      resolve_type(:unknown)
   end
   
   def self.resolve_type( name )
      return name if name.is_a?(Schema::Type)
      Schema.current do |schema|
         schema.types.member?(name) ? schema.types[name] : schema.send((name.to_s + "_type").intern)      
      end
   end
   
   def self.capture_type( type, production = nil )
      resolve_type(type).placeholder(production)
   end
      
   
   def self.capture( value, production = nil )
      case value
      when Placeholder, NilClass
         return value
      when Schema::Type
         return value.placeholder(production)
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
      when String
         return LiteralScalar.new(value, resolve_type(:text).make_specific(:length => value.length))
      else
         fail "FormulaCapture.capture() does not currently handle objects of type #{value.class.name}"
      end
   end
   
   
   def self.capture_method_call(result_type, receiver, method_name, args = [], block = nil )
      capture_type(result_type, Productions::MethodCall.new(receiver, method_name, args, block))
   end
      

   def self.capture_binary_operator( operator, lhs, rhs )
      lhs         = capture(lhs)
      rhs         = capture(rhs)
      result_type = merge_types(lhs.get_type, rhs.get_type)
      production  = Productions::BinaryOperator.new(operator, lhs, rhs)
      
      result_type.placeholder(production)
   end
   
   def self.capture_comparison_operator( operator, lhs, rhs )
      lhs         = capture(lhs)
      rhs         = capture(rhs)
      production  = Productions::Comparison.new(operator, lhs, rhs)

      resolve_type(:boolean).placeholder(production)
   end   
   
   def self.capture_logical_and( lhs, rhs )
      boolean = resolve_type(:boolean)
      lhs     = capture(lhs)
      rhs     = capture(rhs)
      assert(boolean.assignable_from?(lhs.get_type), "expected boolean expression on left-hand of logical and, found #{lhs.get_type.description}" )
      assert(boolean.assignable_from?(rhs.get_type), "expected boolean expression on right-hand of logical and, found #{rhs.get_type.description}")

      boolean.placeholder(Productions::And.new([lhs, rhs]))
   end

   def self.capture_logical_or( lhs, rhs )
      boolean = resolve_type(:boolean)
      lhs     = capture(lhs)
      rhs     = capture(rhs)
      assert(boolean.assignable_from?(lhs.get_type), "expected boolean expression on left-hand of logical or, found #{lhs.get_type.description}" )
      assert(boolean.assignable_from?(rhs.get_type), "expected boolean expression on right-hand of logical or, found #{rhs.get_type.description}")

      boolean.placeholder(Productions::Or.new([lhs, rhs]))
   end

   def self.capture_formula( formula_context, block, result_type = nil, join_compatible_only = true )
      formula_context.get_type.schema.enter do
         Language::FormulaDefinition.module_exec(formula_context, &block).use do |captured_formula|
            type_check(:captured_formula, captured_formula, Language::Placeholder)
            if result_type then
               if join_compatible_only then
                  assert(result_type.join_compatible?(captured_formula.get_type), "expected expression result to be join compatible with #{result_type.description}, found #{captured_formula.get_type.description} instead")
               else                                                             
                  assert(result_type.assignable_from?(captured_formula.get_type), "expected expression result to be assignable to #{result_type.description}, found #{captured_formula.get_type.description} instead")
               end
            end
         end
      end
   end
      
end # FormulaCapture
end # Language
end # Schemaform





# =============================================================================================
#                                        Placeholder Capture
# =============================================================================================

module Schemaform
class Schema
   
   class Component
      def placeholder( production = nil )
         fail_unless_overridden
      end
      
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :apply
            method, type, *parameters = *args
            parameters = parameters.collect{|p| Language::FormulaCapture.capture(p)}
            Language::FormulaCapture.capture_type(type, Language::Productions::Application.new(method, receiver, parameters))
         else
            capture_accessor(receiver, method_name.to_s.tr("!", "").intern)
         end
      end
      
      def capture_accessor( receiver, attribute_name )
         nil
      end
   end   
   
   class Type
      def placeholder( production = nil )
         Language::Placeholder.new(self, production)
      end      
   end
   
   class UnknownType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :+, :-, :*, :/, :%
            Language::FormulaCapture.capture_binary_operator(method_name, receiver, args.shift)
         when :==, :<, :>, :<=, :>=
            Language::FormulaCapture.capture_comparison_operator(method_name, receiver, args.shift)
         else
            super
         end
      end      
   end
   
   class ScalarType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :+, :-, :*, :/, :%
            Language::FormulaCapture.capture_binary_operator(method_name, receiver, args.shift)
         when :==, :<, :>, :<=, :>=
            Language::FormulaCapture.capture_comparison_operator(method_name, receiver, args.shift)
         else
            super
         end
      end      
   end
   
   class BooleanType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :&
            Language::FormulaCapture.capture_logical_and(receiver, args.shift)
         when :|
            Language::FormulaCapture.capture_logical_or(receiver, args.shift)
         else
            super
         end
      end
   end
   
   class NumericType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :floor, :ceil
            Language::FormulaCapture.capture_method_call(:integer, receiver, method_name, args, block)
         else
            super
         end
      end
   end
   
   
   class CollectionType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :+, :-
            Language::FormulaCapture.capture_binary_operator(method_name, receiver, args.shift)
         when :==
            Language::FormulaCapture.capture_comparison_operator(method_name, receiver, args.shift)
         when :sum, :average
            check{ assert(!receiver.get_type.effective_type.member_type.collection_type?, "how do we do aggregation across nested collections?") }
            receiver.get_type.effective_type.member_type.placeholder(Language::Productions::Aggregation.new(receiver, method_name))
         when :count
            check{ assert(!receiver.get_type.effective_type.member_type.collection_type?, "how do we do aggregation across nested collections?") }
            Language::FormulaCapture.capture_type(:integer, Language::Productions::Aggregation.new(receiver, method_name))
         else
            return super unless naming_type?
            
            case method_name
            when :where
               formula_context = @member_type.placeholder(Language::Productions::EachTuple.new(receiver))
               criteria        = Language::FormulaCapture.capture_formula(formula_context, block, schema.boolean_type)
               self.placeholder(Language::Productions::Restriction.new(receiver, formula_context, criteria))
            when :project
               warn_todo("validation on projection results")
               placeholders = block ? block.call(@member_type.placeholder()) : args.collect{|name| @member_type.tuple[name].placeholder()}
               self.placeholder(Language::Productions::Projection.new(receiver, placeholders))
            else
               super
            end
         end
      end

      def capture_accessor( receiver, attribute_name )
         member_type = member_type().evaluated_type
         if member_type.responds_to?(:attribute?) then
            if captured = member_type.capture_method(receiver, attribute_name) then
               return self.class.build(captured.get_type).placeholder(Language::Productions::Each.new(captured))
            end            
         end
         
         return nil
      end
   end
   
   
   class ListType
      def capture_method( receiver, method_name, args = [], block = nil )
         case method_name
         when :join
            Language::FormulaCapture.capture_method_call(:text, receiver, method_name, args, block )
         else
            super
         end
      end
   end
   

   class SetType
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

               Schema::ListType.build(member_type, :order => order_attributes).placeholder(Language::Productions::OrderBy.new(receiver, *order_attributes))
            else
               super
            end
         when :member?
            search_term = Language::FormulaCapture.capture(args.shift)
            production  = Language::Productions::MemberOfSet.new(receiver, search_term)
            Language::FormulaCapture.resolve_type(:boolean).placeholder(production)
         else
            super
         end
      end
   end
   
   

   class EntityReferenceType
      def capture_accessor( receiver, attribute_name )
         return nil unless attribute?(attribute_name)
         
         entity = referenced_entity()
         tuple  = entity.root_tuple.placeholder(Language::Productions::FollowReference.new(receiver))
         Language::Attribute.new(entity.heading[attribute_name], Language::Productions::Accessor.new(tuple, attribute_name))
      end
   end
   
   class TupleType
      def placeholder( production = nil )
         @tuple.placeholder(production)
      end
      
      def capture_method( receiver, method_name, args = [], block = nil )
         @tuple.capture_method(receiver, method_name, args, block)
      end
   end
   
   
   class Tuple
      def capture_accessor( receiver, attribute_name )
         return nil unless attribute?(attribute_name)
         Language::Attribute.new(self[attribute_name], Language::Productions::Accessor.new(receiver, attribute_name))
      end
      
      def placeholder( production = nil )
         root_tuple === self ? Language::EntityTuple.new(context_entity, production) : Language::Tuple.new(self, production)
      end
   end
   
   
   
   
   class Attribute
      def placeholder( production = nil )
         Language::Attribute.new(self, production)
      end
      
      def formula()
         if defined?(@proc) then
            unless @formula || @analyzing
               # debug("processing in #{full_name}")

               schema.enter do
                  begin
                     @analyzing = true  # Ensure any self-references don't retrigger analysis
                     @formula   = Language::FormulaCapture.capture_formula(root_tuple.placeholder(), @proc).use do |captured_formula|
                        type_check(:captured_formula, captured_formula, Language::Placeholder)
                     end
                  ensure
                     @analyzing = false
                  end
               end
            end
         end
         
         @formula
      end
      
      def formula_type()
         if formula() then
            type = @formula.get_type
            unless type.unknown_type?
               # debug("#{full_name} resolved to #{type.description}")
               return type 
            end
         end
         
         # debug("#{full_name} could not be resolved at this time")
         return nil
      end

   end
   
   class DerivedAttribute
      def type()
         (@type ||= formula_type) || schema.unknown_type
      end
   end
   
   class OptionalAttribute
      def type()
         (@type ||= formula_type) || schema.unknown_type         
      end
   end
   
   class Entity
      def placeholder( production = nil )
         Language::Entity.new(self, production)
      end
      
      def project_attributes( specification )
         if specification.is_a?(Proc) then
            placeholder.project(&specification).get_production.attribute_definitions
         else
            placeholder.project(*specification).get_production.attribute_definitions
         end
      end

      def project_attribute_expressions( specification )
         project_attributes(specification).get_production.attributes.collect{|attribute| attribute.evaluate}
      end
   end

   class DerivedEntity
      def type()
         (@type ||= formula_type) || schema.unknown_type
      end
      
      def formula()
         unless @formula || @analyzing
            # debug("processing in #{full_name}")

            schema.enter do
               begin
                  @analyzing = true  # Ensure any self-references don't retrigger analysis
                  @formula   = Language::FormulaDefinition.module_exec(&@proc).use do |captured_formula|
                     type_check(:captured_formula, captured_formula, Language::Placeholder)
                  end
               ensure
                  @analyzing = false
               end
            end
         end
         
         @formula
      end
      
      def formula_type()
         if formula() then
            type = @formula.get_type
            unless type.unknown_type?
               # debug("#{full_name} resolved to #{type.description}")
               return type 
            end
         end
         
         # debug("#{full_name} could not be resolved at this time")
         return nil
      end
   end

   class GeneratedAccessor
      def placeholder( production = nil )
         attributes = attributes()
         
         schema.enter do
            context.placeholder(production).where do |tuple|
               comparisons = []
               attributes.each_with_index do |attribute, index|
                  comparisons << (tuple[attribute.name] == parameter(index))
               end

               and!(*comparisons)
            end
         end
      end
   end
   
   class DefinedAccessor
      def placeholder( production = nil )
         block = @proc

         schema.enter do
            context.placeholder(production).where do |tuple|
               Language::FormulaDefinition.module_exec(tuple, &block)
            end
         end
      end
   end
   

end # Schema
end # Schemaform




# =============================================================================================
#                                        Path Discovery
# =============================================================================================

module Schemaform
class Schema

   class Entity

      #
      # Recurses through the attributes, calling your block at each with the attribute
      # and an expression indicating how it arrived there. When you find what you are 
      # looking for, you can build the final Marker around the path and return (or return 
      # whatever else you want -- we won't judge).

      def search( path = nil, &block )
         unless @heading.attributes.empty?
            path = root_tuple.placeholder() if path.nil?
            @heading.attributes.each do |attribute|
               attribute_path = attribute.placeholder(path)
               if result = yield(attribute, attribute_path) || attribute.search(attribute_path, &block) then
                  return result
               end
            end
         end
         
         return nil
      end

   end
   
   
   class Tuple
      def search( path = nil, &block )
         unless @attributes.empty?
            path = root_tuple.placeholder() if path.nil?
            @attributes.each do |attribute|
               attribute_path = attribute.placeholder(path)
               if result = yield(attribute, attribute_path) || attribute.search(attribute_path, &block) then
                  return result
               end
            end
         end
         
         return nil
      end
   end
   
   
   class WritableAttribute
      def search( path = nil, &block )
         if evaluated_type.is_a?(TupleType) then
            return evaluated_type.tuple.search(path, &block)
         else
            return super
         end
      end
   end
   

   class Component
      def search( path = nil, &block )
         return nil
      end
   end
   
end # Schema
end # Schemaform




