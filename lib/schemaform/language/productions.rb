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


module Schemaform
module Language
   
   #
   # Base class for productions -- things that describe who a Placeholder was calculated.

   class Production
      
      include QualityAssurance
      
      def print_to( printer )
         width = fields.collect{|n| n.to_s.length}.max()
         each do |name, value|
            printer.label(name.to_s.ljust(width)){ printer.print(value) }
         end
      end
      

      #
      # Defines a Production class that takes a standard parameter list and provides
      # retrievers to access them.
   
      def self.define( *parameters )
         Class.new(self) do
            @@defined_subclass_field_lists[self] = parameters
            
            define_method(:initialize) do |*values|
               fields.each{|name| instance_variable_set("@#{name}".intern, values.shift)}
            end

            parameters.each do |name|
               attr_reader "#{name}".intern
            end
         end         
      end
      
      def fields()
         @@defined_subclass_field_lists[self.class]
      end
      
      def each()
         fields.each do |name|
            yield(name, instance_variable_get("@#{name}".intern))
         end
      end
      
      def description()
         self.class.unqualified_name
      end
      
      @@defined_subclass_field_lists = {}
      
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
      #          Printer.print(scope)
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
