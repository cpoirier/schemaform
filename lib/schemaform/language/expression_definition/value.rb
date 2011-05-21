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

require Schemaform.locate("base.rb")

#
# Base class for values.

module Schemaform
module Language
module ExpressionDefinition
class Value < Base

   def initialize( type, production = nil )
      super(type)
      @production = production
   end
   
   def +(  rhs ) ; Value.binary_operator(:+ , self, rhs)  ; end
   def -(  rhs ) ; Value.binary_operator(:- , self, rhs)  ; end
   def *(  rhs ) ; Value.binary_operator(:* , self, rhs)  ; end
   def /(  rhs ) ; Value.binary_operator(:/ , self, rhs)  ; end
   def %(  rhs ) ; Value.binary_operator(:% , self, rhs)  ; end
   def <(  rhs ) ; Value.binary_operator(:< , self, rhs)  ; end
   def >(  rhs ) ; Value.binary_operator(:> , self, rhs)  ; end

   def <=( rhs ) ; Value.binary_operator(:<=, self, rhs) ; end
   def >=( rhs ) ; Value.binary_operator(:>=, self, rhs) ; end
   
   def apply( method, type, *parameters )
      parameters = parameters.collect{|p| Base.markup(p)}
      production = Productions::Application.new(self, method, parameters)
      Base.type(type).marker(production)
   end

   def sum()   ; Value.aggregation(:sum  , self) ; end
   def count() ; Value.aggregation(:count, self) ; end
   
   
   def method_missing( symbol, *args, &block )
      result_type = @type.method_type(symbol, *args, &block) or return super
      result_type.marker(Productions::MethodCall.new(self, symbol, *args, &block))
   end
   
   def self.binary_operator( operator, lhs, rhs )
      lhs         = Base.markup(lhs)
      rhs         = Base.markup(rhs)
      result_type = Base.merge_types(lhs.type, rhs.type)
      production  = Productions::BinaryOperator.new(operator, lhs, rhs)
      
      result_type.marker(production)
   end
   
   def self.aggregation( operator, marker )
      if marker.type.is_a?(Schema::CollectionType) then
         marker.type.member_type.marker(Productions::Aggregation.new(operator, marker))
      else
         marker
      end
   end

end # Value
end # ExpressionDefinition
end # Language
end # Schemaform

