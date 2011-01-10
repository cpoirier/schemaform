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
module Fields

class TupleField < Field
   def initialize( context, name, &block )
      super( context, name, nil )
      @tuple = Tuple.new( context.schema, self )
      @dsl   = DefinitionLanguage.new( self )

      @dsl.instance_eval(&block) if block_given?
   end
   
   attr_reader :tuple
      
   def resolve( supervisor, tuple_expression = nil )
      supervisor.monitor(self, path()) do
         close()
         @tuple.resolve( supervisor, tuple_expression )
      end
   end
   
   def close()
      if @expression.nil? then
         @tuple.close()
         @expression = Expressions::Fields::TupleField.new(self) 
      end
   end
   
   
   
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   class DefinitionLanguage < Tuple::DefinitionLanguage
      def initialize( tuple_field )
         super( tuple_field.tuple )
      end
   end
   
end




end # Fields
end # Definitions
end # Schemaform
