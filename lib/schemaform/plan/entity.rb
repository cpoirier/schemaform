#!/usr/bin/env ruby
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
# Wraps a Schema-defined Entity for use at runtime.

module Schemaform
module Plan
class Entity
   
   def initialize( definition )
      @definition = definition
   end

   attr_reader :definition
   
   def accessors()
      @definition.accessors
   end
   
   def operations()
      @definition.operations
   end

end # Entity
end # Plan
end # Schemaform
