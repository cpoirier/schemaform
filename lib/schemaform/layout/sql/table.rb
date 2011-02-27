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
module Layout
module SQL
class Table

   attr_reader :name, :fields, :primary_key
   
   def initialize( master, name )
      @master      = master
      @name        = name
      @fields      = []
      @keys        = []
      @primary_key = Key.new( self )
      
      @map.add_table( self )
   end
   
   def define_field( name, type, allow_nulls = false )
      @fields << Field.new( self, name, type, allow_nulls )
   end


   def add_key( key )
      @keys << key
   end
   
   def to_sql()

      #
      # Produce field definitions.
      
      name_width        = @fields.max_by{|f| f.name.to_s.length}.name.to_s.length
      type_width        = @fields.max_by{|f| f.type.length}.type.length
      field_definitions = @fields.collect{|field| field.to_sql(name_width, type_width)}
      
      #
      # Produce primary and unique keys.
      
      key_definitions = []
      key_definitions << @primary_key.to_sql("primary key") if @primary_key && !@primary_key.empty?
      
      #
      # Complete the SQL.
      
      lines = (field_definitions + key_definitions).collect{|line| "   #{line}"}
      line_width = lines.max_by{|l| l.length}.length
      
      "create table #{@name}\n(\n#{lines.collect{|l| l.ljust(line_width)}.join(",\n")}\n);"
   end

end # Table
end # SQL
end # Layout
end # Schemaform