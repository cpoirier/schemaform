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
# Represents a field in a SQL Table.

module Schemaform
module Mapping
class Field

   def initialize( table, name, type, allow_nulls = false )
      @table       = table
      @name        = name
      @type        = type
      @allow_nulls = allow_nulls
      
      @table.add_field( self )
   end
   
   attr_reader :name, :type
   
   def allow_nulls?()
      @allow_nulls
   end
   
   def to_sql( name_width = 0, type_width = 0 )
      @name.to_s.ljust(name_width) + " " + @type.ljust(type_width) + " " + (@allow_nulls ? "" : "not") + " null"
   end
   

end # Field
end # Mapping
end # Schemaform