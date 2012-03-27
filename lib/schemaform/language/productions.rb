#!/usr/bin/env ruby
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

require Schemaform.locate("schemaform/utilities/printable_struct.rb")


module Schemaform
module Language
   
   #
   # Base class for productions -- things that describe who a Placeholder was calculated.

   class Production < PrintableStruct
   end # Production
   

   module Productions

      # ==========================================================================================
      # Basic
   
      ValueAccessor   = Production.define( :attribute                              )
      FollowReference = Production.define( :reference                              )
      BinaryOperator  = Production.define( :operator, :lhs, :rhs                   )
      Accessor        = Production.define( :receiver, :symbol                      )
      MethodCall      = Production.define( :receiver, :symbol, :parameters, :block )
      Application     = Production.define( :method, :subject, :parameters          )
      Each            = Production.define( :operation                              )
      EachTuple       = Production.define( :relation                               )
      Path            = Production.define( :step                                   )

      # ==========================================================================================
      # Logic
          
      IfThenElse      = Production.define( :condition, :true_branch, :false_branch )
      PresentCheck    = Production.define( :attribute, :true_branch, :false_branch )
      Comparison      = Production.define( :operator, :lhs, :rhs                   )
      And             = Production.define( :clauses )
      Or              = Production.define( :clauses )
      Not             = Production.define( :subject )

      # ==========================================================================================
      # Relational

      Restriction     = Production.define( :relation, :tuple, :criteria )
      Projection      = Production.define( :relation, :attributes       )
      Aggregation     = Production.define( :relation, :operator         )
      OrderBy         = Production.define( :relation, :ordering         )
      RelatedTuples   = Production.define( :relation, :link_path        )

      # ==========================================================================================
      # Other
      
      MemberOfSet     = Production.define( :set, :value )
      
      # class ImpliedScope < Production
      #    def initialize( scope )
      #       if scope.is_a?(Language::Attribute) && scope.get_production.is_a?(Accessor) && scope.get_production.symbol == :email
      #          Schemaform.debug.dump(scope)
      #          fail 
      #       end
      #       @scope = scope
      #    end
      # end


      class Projection
         def attribute_definitions()
            @attributes.collect{|attribute| attribute.get_definition}
         end
      end
   end

   
   
   
end # Language
end # Schemaform


Dir[Schemaform.locate("productions/*.rb")].each{|path| require path}
