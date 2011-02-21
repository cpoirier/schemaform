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
# Represents a key on a Table.

module Schemaform
module Mapping
class Key

   def initialize( table, name = nil )
      @table  = table
      @name   = name
      @fields = []
      
      table.add_key( self )
   end
   
   attr_reader :name, :fields
   
   def add_field( field )
      @fields << field
   end
   
   def to_sql( name_override = nil )
      name = name_override || "unique index #{@name}"
      "#{name} (#{@fields.collect{|f| f.name.to_s}.join(", ")})"
   end
   
   def empty?
      @fields.empty?
   end

end # Key
end # Mapping
end # Schemaform