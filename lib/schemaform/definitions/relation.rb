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

require Schemaform.locate("set.rb"  )
require Schemaform.locate("tuple.rb")


#
# Base class for named relations.

module Schemaform
module Definitions
class Relation < Set

   def initialize( heading, schema, name )
      super(heading, schema, name, RelationType)
      type_check(:heading, heading, Tuple)
   end
   
   def heading()
      @member_definition
   end
   
   
   def project( *attributes )
      Relation.new(schema, nil, heading.project(*attributes))
   end



   # ==========================================================================================
   #                                     Expression Interface
   # ==========================================================================================
   
   class RelationVariable < ExpressionResult
      def initialize( definition, production = nil )
         super(definition, production)
      end
      
      def method_missing( symbol, *args, &block )
         return super unless @definition.heading.member?(symbol)
         @definition.project(symbol).variable(Expressions::Projection.new(self, symbol))
      end
   end
   
   def variable( production = nil )
      RelationVariable.new(self, production)
   end
   
   

end # Relation
end # Definitions
end # Schemaform