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
Dir[Schemaform.locate("expression_definition/*.rb")].each{|path| require path}


# =============================================================================================
#                                        Marker Production
# =============================================================================================

module Schemaform
class Schema
   
   class Type < Element
      def marker( production = nil )
         fail "what kind of marker should #{self.class.name} have?"
      end   
   end
   
   class UnknownType < Type
      def marker( production = nil )
         Language::ExpressionDefinition::Value.new(self, production)
      end
   end

   class ScalarType < Type
      def marker( production = nil )
         Language::ExpressionDefinition::Value.new(self, production)
      end
   end
   
   class CollectionType < Type
      def marker( production = nil )
         Language::ExpressionDefinition::Value.new(self, production)
      end
   end
   
   class EnumeratedType < ScalarType
      def marker( production = nil )
         evaluated_type.marker(production)
      end
   end
   
   class ReferenceType < Type
      def marker( production = nil )
         Language::ExpressionDefinition::EntityReference.new(self, production)
      end
   end
   
   class UserDefinedType < Type
      def marker( production = nil )
         fail "TODO: how does this interact with effective type?"
      end
   end
   
   
   
   
   class Tuple < Element
      def marker( production = nil )
         return Language::ExpressionDefinition::Tuple.new(self, production) unless production.nil?
         return @marker if @marker
         @marker = Language::ExpressionDefinition::Tuple.new(self, production)
      end
      
      def formula_context( production = nil )
         @formula_context ||= Language::ExpressionDefinition::Tuple.new(self, production)
      end      
   end
   
   class Attribute < Element
      def marker( production = nil )
         Language::ExpressionDefinition::Attribute.new(self, production)
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
         if @analysis.nil? then
            debug("processing in #{full_name}")

            Thread[:expression_contexts] = [] unless Thread.key?(:expression_contexts)
            Thread[:expression_contexts].push_and_pop(schema()) do
               begin
                  @analysis = false  # Set false to ensure any self-references don't retrigger analysis
                  @analysis = @proc.call(formula_context())
                  assert(!@analysis.type!.unknown_type?, "#{full_name}'s is self-referential and the type cannot be inferred")
               ensure
                  @analysis = nil unless @analysis
               end
            end
         end
         
         @analysis ? @analysis.type! : nil
      end
   end
   
   class VolatileAttribute < DerivedAttribute
      
      def type()
         @type ||= marker.type!
      end
      
      #
      # Volatile attributes are essentially macros. We treat the formula as if it were used
      # inline in the context. However, to enable that, we disallow recursion.

      def marker( production = nil )
         warn_once("TODO: must recursion be excluded from volatile attributes?")
         
         if @analyzing then
            fail "#{full_name} is a self-referencing volatile attribute, which is not presently supported"
         else
            debug("processing in #{full_name}")
            
            Thread[:expression_contexts] = [] unless Thread.key?(:expression_contexts)
            Thread[:expression_contexts].push_and_pop(schema()) do
               begin
                  warn_once("TODO: shouldn't the formula_context for a Volatile attribute link in with the context Production?")
                  @analyzing = true  # Set true to ensure any self-references are detected
                  return @proc.call(formula_context(production))
               ensure
                  @analyzing = false
               end
            end
         end
      end
   end



   class Relation < Element
      def marker( production = nil )
         Language::ExpressionDefinition::Relation.new(context, self, production)
      end
   end
   
   class Entity < Relation
      def formula_context( production = nil )
         warn_once("what does it mean to supply a production to Entity.formula_context()?") if production.nil?
         Language::ExpressionDefinition::EntityTuple.new(self, production)
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
               attribute_path = attribute.marker(path)
               result = yield(attribute, attribute_path) || attribute.definition.search(attribute_path, &block)
               return result if result
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
               attribute_path = attribute.marker(path)
               result = yield(attribute, attribute_path) || attribute.definition.search(attribute_path, &block)
               return result if result
            end
         end
         
         return nil
      end
   end


   class Element
      def search( path = nil, &block )
         return nil
      end
   end
   
end # Schema
end # Schemaform




