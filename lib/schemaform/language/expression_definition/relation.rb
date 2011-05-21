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
# Provides access to a Tuple and its attributes.

module Schemaform
module Language
module ExpressionDefinition
class Relation < Base

   def initialize( definition, production = nil )
      super()
      @production = production
      @definition = definition
   end
   
   def method_missing( symbol, *args, &block )
      attribute  = Base.lookup(@definition.heading.attributes, symbol, args, block) or return super
      projection = attribute.marker(Productions::Projection.new(self, symbol))
      Schema::SetType.build(projection.type).marker(projection)
   end
   
   def count()
      Base.type(:integer).marker(Productions::Aggregation.new(:count, self))
   end
   
   def type()
      @definition.type
   end
   
end # Relation
end # ExpressionDefinition
end # Language
end # Schemaform