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
      @type = type
   end
   
   def type()
      @type ? @type : fail_unless_overridden(self, :type)
   end
   
   def []( name )
      method_missing(name)
   end
   
   def self.markup( object )
      case object
      when Base
         return object
      when NilClass
         return nil
      when Array
         return LiteralList.new(*object.collect{|e| markup(e)})
      when Set
         return LiteralSet.new(*object.collect{|e| markup(e)})
      when FalseClass, TrueClass
         return LiteralScalar.new(object, type(:boolean))
      when Integer
         return LiteralScalar.new(object, type(:integer))
      when Float
         return LiteralScalar.new(object, type(:real))
      else
         fail "Base.markup() does not currently handle objects of type #{object.class.name}"
      end
   end
   
   def self.lookup( container, symbol, args, block )
      return nil unless args.empty? && block.nil?
      return container[symbol] if container.member?(symbol)

      alternate = symbol.to_s.tr("!", "").intern
      container.fetch(alternate, nil)
   end
   
   def self.merge_types( *objects )
      result = type(:unknown)
      
      objects.each do |object|
         next if object.nil?
         result = result.best_common_type(object.is_a?(Schema::Type) ? object : object.type)
      end

      result
   end
   
   def self.type( symbol )
      schema = Thread[:expression_contexts].top
      schema.types.member?(symbol) ? schema.types[symbol] : schema.send((symbol.to_s + "_type").intern)
   end
   
end # Base
end # ExpressionDefinition
end # Language
end # Schemaform

