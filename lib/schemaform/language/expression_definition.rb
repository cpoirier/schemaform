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

#
# comment

module Schemaform

class Schema
   
   class Type < Element
      def marker( production = nil )
         Language::ExpressionDefinition::Marker.new(production, self)
      end   
   end
   
   class ReferenceType < Type
      def marker( production = nil )
         Language::ExpressionDefinition::EntityReference.new(self, production)
      end
   end
   
   class Tuple < Element
      def marker( production = nil )
         return Language::ExpressionDefinition::Tuple.new(self, production) unless production.nil?
         return @marker if @marker
         @marker = Language::ExpressionDefinition::Tuple.new(self, production)
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
   



end # Schema
end # Schemaform

Dir[Schemaform.locate("expression_definition/*.rb")].each{|path| require path}