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
# Represents a standard SQL table.

module Schemaform
module Mapping
class Table

   attr_reader :name, :row_name, :fields, :primary_key
   
   def initialize( map, name, row_name = nil )
      @map         = map
      @name        = name
      @row_name    = row_name || name
      @fields      = []
      @keys        = []
      @primary_key = Key.new( self )
      
      @map.add_table( self )
   end

   def add_field( field )
      @fields << field
   end


   def add_key( key )
      @keys << key
   end
   
   def to_sql()
      name_length       = @fields.inject(0){|current, field| [current, field.name.to_s.length].max}
      field_definitions = @fields.collect{|field| field.to_sql(name_length)}.join("\n   ")
      "create table #{@name}\n(\n   #{field_definitions}\n);"
   end

end # Table
end # Mapping
end # Schemaform