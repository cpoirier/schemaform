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

   def initialize( definition )
      super( nil )
      @definition = definition
      @fields     = {}
      
      #
      # Define one Field expression for each field in the Tuple definition.
      
      @definition.each_field do |field_definition|
         @fields[field_definition.name] = field = Field.new( field_definition )
         instance_class.class_eval do
            define_method field_definition.name do |*args|
               return field
            end
         end
      end
   end
   
   #
   # Returns the Schemaform record identifier expression for this tuple, if known.
   
   def id()      
      check do
         assert( @source.exists?, "source record not identifiable in this context" )
      end

      fail( "TODO: generate ID expression" )
   end
   
   
   #
   # Returns a subset of some relation for which the first (or specified) reference
   # field refers to this tuple (if identifiable).

   def find_matching( relation, on_field = nil )
      fail
      # assert( @source.exists?, "source record not identifiable in this context" )
      # relation = RelationExpression.new( @schema.relation(relation) )
      # relation 
   end
   
   
end # Tuple
end # Expressions
end # Schemaform