#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2012 Chris Poirier
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
# Provides access to a Entity-examplar Tuple and its attributes. This is the Marker passed
# to the Formula for a derived attribute.

module Schemaform
module Language
class Tuple < Placeholder

   def initialize( tuple, production = nil )
      super(tuple.type, production)
      @tuple = tuple
   end
   
   def []( name )
      @tuple.capture_accessor(self, name)
   end
   
   def method_missing( symbol, *args, &block )
      @tuple.capture_method(self, symbol, args, block) or fail "cannot dispatch [#{symbol}] on tuple #{@tuple.full_name}"
   end
   
   def get_description()
      "0x#{self.object_id.to_s(16)} #{@type.description}"
   end
   

end # Tuple
end # Language
end # Schemaform
