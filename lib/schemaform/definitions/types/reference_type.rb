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

require Schemaform.locate("../type.rb")
require Schemaform.locate("../variable.rb")


module Schemaform
module Definitions
class ReferenceType < Type

   def initialize( entity_name, attrs )
      attrs[:base_type] = attrs.fetch(:context).schema.identifier_type unless attrs.member?(:base_type)
      super attrs
      @entity_name = entity_name
      type_check(:entity_name, entity_name, Symbol)
   end
   
   attr_reader :entity_name
   
   
   # ==========================================================================================
   #                                     Expression Interface
   # ==========================================================================================
   
   class ReferenceTypeVariable < Variable

      def initialize( type, production = nil )
         super(type, production)
         p type.schema.full_name
         p type.entity_name
         @tuple = type.schema.entities.find(type.entity_name).heading
      end

      def method_missing( symbol, *args, &block )
         return super unless @tuple.member?(symbol)
         @tuple[symbol].variable(Expressions::Accessor.new(self, symbol))
      end
      
   end # TupleVariable
   
   
   def variable( production = nil )
      ReferenceTypeVariable.new(self, production)
   end
   
   
   
   
   

end # ReferenceType
end # Definitions
end # Schemaform