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
# The base class for variables, intermediates, and results of an expression. These are the 
# things with which you interact when describing a derived attribute or default value in the 
# Schemaform definition language. Your expression must return one, but you should never create
# one directly.

module Schemaform
module Language
module ExpressionDefinition
class Base
   include QualityAssurance

   def initialize( type = nil )
      @type       = type
   end
   
   def namer!()
      @namer
   end
   
   def effective!()
      self
   end
   
   def type!()
      @type ? @type : fail_unless_overridden(self, :type!)
   end
   
   def []( name )
      method_missing(name)
   end
   
   def markup!( object )
      case object
      when Base
         return object
      when NilClass
         return nil
      when Array
         return LiteralList.new(*object.collect{|e| markup!(e)})
      when Set
         return LiteralSet.new(*object.collect{|e| markup!(e)})
      when FalseClass, TrueClass
         return LiteralScalar.new(object, Thread[:expression_contexts].top.boolean_type)
      else
         fail "no support for #{object.class.name}"
      end
   end
   
end # Base
end # ExpressionDefinition
end # Language
end # Schemaform

