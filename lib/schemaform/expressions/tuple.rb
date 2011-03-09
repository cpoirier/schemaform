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

require Schemaform.locate("expression.rb")


#
# A tuple, potentially linked to an entity record (if identifiable).

module Schemaform
module Expressions
class Tuple < Expression

   attr_reader :attributes
   

   #
   # Returns a subset of some relation for which the first (or specified) reference
   # attribute refers to this tuple (if identifiable).

   def find_matching( relation, on_attribute = nil )
      relation_definition = @definition.schema.find_relation(relation)
      assert( relation_definition, "unable to find relation [#{relation}]" )
      return relation_definition.expression
   end
   



   
   # ==========================================================================================
   #                                   For Schemaform Use Only
   # ==========================================================================================

   def initialize( definition )
      super()
      @definition = definition
      @attributes     = {}
   end
   
   def resolve( relation_types_as = :reference )
      @definition.resolve( :reference )
   end

   def method_missing( symbol, *args, &block )
      if @definition.attribute?(symbol) then
         attribute_definition = @definition.attributes[symbol]
         attribute_expression = attribute_definition.expression
         @attributes[symbol]  = attribute_expression
         instance_class.class_eval do
            define_method symbol do |*args|
               return attribute_expression
            end
         end
         return send( symbol, *args, &block )
      else
         raise NoMethodError.new(nil, symbol, self)
      end
   end
   
   
end # Tuple
end # Expressions
end # Schemaform