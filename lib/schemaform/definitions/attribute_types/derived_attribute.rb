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



module Schemaform
module Definitions
class DerivedAttribute < Attribute
   def initialize( tuple, modifiers = {}, proc = nil, &block )
      super(tuple)
      @modifiers = modifiers
      @forumla   = proc || block
   end

   def recreate_in( tuple )
      self.class.new( tuple, @block ).tap do |recreation|
         recreation.name = name
      end
   end
   
   def resolve( relation_types_as = :reference )
      supervisor.monitor(self) do
         annotate_errors( :attribute => full_name() ) do 
            result_expression = @block.call( root_tuple.expression )
            type_check( :result_expression, result_expression, Expressions::Expression )
            result_expression.resolve( relation_types_as )
         end
      end   
   end
   
end
end # Definitions
end # Schemaform

