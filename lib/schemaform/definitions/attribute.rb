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

require Schemaform.locate("definition.rb")
require Schemaform.locate("expression_result.rb")


#
# An Attribute in a TupleType.

module Schemaform
module Definitions
class Attribute < Definition
   
   def initialize( tuple, definition )
      super(tuple)
      @definition = definition
      if @definition.named? && @definition.is_a?(Tuple) then
         p @definition.full_name
      end
         
      @definition.context = self unless @definition.named?
   end

   attr_reader :definition
   
   alias tuple context
   
   def root_tuple()
      tuple.root_tuple
   end
   
   def type()
      fail_unless_overridden(self, :type)
   end
   
   def writable?()
      false
   end
   
   def optional?()
      false
   end
   
   def recreate_in( tuple )
      self.class.new( tuple, @definition ).tap do |recreation|
         recreation.name = name
      end
   end
   
   def tuple_variable()
      @tuple.variable()
   end

   
   
   # ==========================================================================================
   #                                     Expression Interface
   # ==========================================================================================
   
   class AttributeVariable < ExpressionResult

      def initialize( definition, production = nil )
         super(definition, production)
      end

      def method_missing( symbol, *args, &block )
         handler = @definition.definition.variable(ImpliedContext.new(self))
         handler.send(symbol, *args, &block)
      end
   end # AttributeVariable
   
   
   def variable( production )
      AttributeVariable.new(self, production)
   end
   




end # Attribute
end # Definitions
end # Schemaform


Dir[Schemaform.locate("attribute_types/*.rb")].each {|path| require path}
