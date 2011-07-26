#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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
# Base class for values and variables and results within an expression.

module Schemaform
module Language
class Placeholder
   include QualityAssurance
   extend  QualityAssurance

   def initialize( type, production = nil )
      @type       = type
      @production = production
   end
   
   attr_reader :type, :production
   
   def ==( rhs )
      @type.capture_method(self, :==, [rhs])
   end
   
   def method_missing( symbol, *args, &block )
      @type.capture_method(self, symbol, args, block) or fail "cannot dispatch [#{symbol}] on type #{@type.description} (#{@type.class.name})"
   end
   
end # Placeholder
end # Language
end # Schemaform


Dir[Schemaform.locate("placeholders/*.rb")].each{|path| require path}
