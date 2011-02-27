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
# Represents a single field in a table.  Name and type are complex objects, to be flattened
# once the adapter is known.

module Schemaform
module Layout
module SQL
class Field

   def initialize( table, name, type, allow_nulls = false )
      @table = table
      @name  = name
      @type  = type
      @allow_nulls = allow_nulls
   end
   
   attr_reader :table, :name, :type, :allow_nulls

end # Field
end # SQL
end # Layout
end # Schemaform