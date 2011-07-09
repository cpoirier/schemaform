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

require Schemaform.locate("component.rb")


#
# A field within a table. Unlike attributes in the definition series, fields have only a name
# and a type.

module Schemaform
module Adapters
module Generic
class Field < Component

   def initialize( context, name, sf_type, sql_info = nil, *modifiers )
      super( context, name )
      @sf_type   = sf_type
      @modifiers = modifiers
      @sql_type, @quoted = *sql_info
   end
   
   attr_reader :sf_type, :sql_type, :modifiers
   
   def describe( indent = "", name_override = nil, suffix = nil )
      type_descriptor = if @sql_type then
         [@sql_type, *modifiers].join(" ")
      else
         @sf_type.description()
      end
      
      super indent, name_override, type_descriptor
   end
   
   def sql_value( value )
      if value.nil? then
         "null"
      elsif value == [] then
         "?"
      elsif @quoted then
         quote_string(value.to_s)
      else
         value.to_s
      end
   end
   
   def to_sql_create()
      [sql_name(), @sql_type, *modifiers].join(" ")
   end
   
   def to_sql_comparison( value, operator = "=" )
      value_string = if value.nil? then 
         if operator == "=" then
            "#{sql_name()} is null"
         else 
            "#{sql_name()} is not null"
         end
      else
         "#{sql_name()} #{operator} #{sql_value(value)}"
      end
   end


end # Field
end # Generic
end # Adapters
end # Schemaform
