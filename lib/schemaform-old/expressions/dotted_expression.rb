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


#
# Captures dotted expressions of the form x.y

module Schemaform
module Expressions
class DottedExpression < Expression

   def initialize( expression, attribute, type )
      @expression = expression
      @attribute  = attribute
      @type       = type
   end


   def method_missing( symbol, *args, &block )
      super unless args.empty? && block.nil?
      
      #
      # Okay, it's a potential accessor.  Let's see if we can do something with it.
      
      case @type.resolve.type_info.to_s
      when "scalar"
         super

      when "reference"
         referenced_entity = @type.resolve.entity
         tuple = referenced_entity.resolve.heading
         super unless tuple.member?(symbol)
         return DottedExpression.new(self, symbol, tuple.attributes[symbol].resolve()) 
         
      when "set"
         member_type = @type.resolve.member_type.resolve
         if member_type.
            
            
         
         Expressions.build_
      end
      
      send( @type.resolve.type_info.specialize("method_missing_for", "type"), symbol, *args, &block )
   end


end # DottedExpression
end # Expressions
end # Schemaform