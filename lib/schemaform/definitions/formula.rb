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
# A raw expression within the Definition, not yet processed into real Expressions. Really, it's
# a way of bringing the Ruby Proc into the Definition tree. I know—I need help.

module Schemaform
module Definitions
class Formula < Thing

   def initialize( proc, modifiers = {}, context = nil, name = nil, &launcher )
      super(context, name)
      type_check(:proc, proc, Proc)
      
      @modifiers         = modifiers
      @raw_expression    = proc
      @expression_result = nil
      @launcher          = launcher
   end
   
   attr_reader :raw_expression, :modifiers
      
   def type()
      variable.type
   end
   
   def variable( production = nil )
      if @expression_tree.nil? then
         supervisor.monitor(self) do 
            if @launcher then
               @expression_tree = @launcher.call(@raw_expression, production)
            else
               @expression_tree = @raw_expression.call(production)
            end
         end
      end
      
      @expression_tree
   end
   
   


end # Formula
end # Definitions
end # Schemaform

