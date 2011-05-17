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

   class NumericType < ScalarType
      def marker( production = nil )
         Language::ExpressionDefinition::Number.new(self, production)
      end
   end
   
   class EnumeratedType < ScalarType
      def marker( production = nil )
         effective_type.marker(production)
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
   end
   
   class OptionalAttribute < WritableAttribute
      def marker( production = nil )
         Language::ExpressionDefinition::OptionalAttribute.new(self, production)
      end
   end



   class Relation < Set
      def marker( production = nil )
         Language::ExpressionDefinition::Relation.new(self, production)
      end
   end
   
   class Entity < Relation
      def formula_context( production = nil )
         @formula_context ||= Language::ExpressionDefinition::EntityTuple.new(self, production)
      end
   end


   
   class Formula < Element
      def marker( production = nil )
         warn_once("TODO: how should we detect resolution loops in Formula?")
         if !@result then
            if @result.nil? then
               @result = @proc.call(*(@parameters.collect{|parameter| parameter.formula_context}))
            else
               @proc.call(*(@parameters.collect{|parameter| parameter.formula_context}))
            end
         end
         
         @result
      end
   end

   class Scalar < Element
      def marker( production = nil )
         type.marker(production)
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




