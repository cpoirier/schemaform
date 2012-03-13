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

require Schemaform.locate("productions.rb")
require Schemaform.locate("placeholder.rb")

module Schemaform
module Language
   
   module FormulaInversion
      extend QualityAssurance
   end # FormulaInversion


end # Language
end # Schemaform




# =============================================================================================
#                                      Placeholder Inversion
# =============================================================================================

module Schemaform
class Schema
   
   def build_maintainers()
      @entities.each do |entity|
         entity.build_maintainers()
      end
   end
   
   class Entity < Component
      def build_maintainers()
         structure.build_maintainers( )
      end
   end

   class Element < Component
      def build_maintainers( target_element = nil )         
         
      end
   end
   
   class Collection < Element
      def build_maintainers( target_element = nil )
         @member.build_maintainers(target_element)
      end 
   end
   
   class Tuple < Element
      def build_maintainers( target_element = nil )
         @attributes.each do |attribute|
            attribute.build_maintainers(target_element)
         end
      end
   end
   
   class Attribute < Component
      def build_maintainers( target_element = nil )
         structure.build_maintainers(structure)
      end
   end
   
end # Schema
end # Schemaform

