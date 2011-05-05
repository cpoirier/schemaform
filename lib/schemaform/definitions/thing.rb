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
# Base type for things that can be held in a variable or attribute or other addressable 
# container.

module Schemaform
module Definitions
class Thing < Definition

   def initialize( context, name = nil )
      super(context, name)
   end
   
   def type()
      fail_unless_overridden self, :type
   end
   
   def variable(production = nil)
      fail_unless_overridden self, :variable
   end
   

end # Thing
end # Definitions
end # Schemaform