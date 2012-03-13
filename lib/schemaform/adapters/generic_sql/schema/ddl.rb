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
# Adds entry points to the Adapter that genereate SQL create statements.

module Schemaform
module Adapters
module GenericSQL
class Adapter
   
   
   #
   # Renders some Adapter object into a SQL create statement.
   
   def render_sql_create( object, *data )
      dispatch(:render_sql_create, object, *data)
   end

   def render_sql_create_schema( schema )
      name_width = schema.tables.members.collect{|table| table.fields.collect{|field| field.name.to_s.length}.max()}.max()
      type_width = schema.tables.members.collect{|table| table.fields.collect{|field| field.type.sql.length }.max()}.max()
      
      schema.tables.members.collect{|table| render_sql_create(table, name_width, type_width)}.join("\n\n")
   end

   def render_sql_create_table( table, name_width = 0, type_width = 0 )
      warn_todo("add keys and indices to table create")
      
      name_width ||= table.name_width()
      type_width ||= table.type_width()
      
      fields  = table.fields.collect{|field| render_sql_create(field, name_width, type_width)}
      keys    = []
      clauses = fields + keys
      
      "CREATE TABLE #{quote_identifier(table.name)}\n(\n   #{clauses.join(",\n   ")}\n);"
   end
      
   def render_sql_create_field( field, name_width, type_width )
      modifiers = field.marks.collect{|mark| render_sql_create(mark)}
      [quote_identifier(field.name).ljust(name_width+3), field.type.sql.ljust(type_width+1), *modifiers].join(" ")
   end
   
   def render_sql_create_generated_mark( mark )
      "AUTOINCREMENT"
   end
   
   def render_sql_create_primary_key_mark( mark )
      "PRIMARY KEY"
   end
   
   def render_sql_create_required_mark( mark )
      "NOT NULL"
   end
   
   def render_sql_create_optional_mark( mark )
      "    NULL"
   end
   
   def render_sql_create_reference_mark( mark )
      clauses = []
      clauses << "REFERENCES #{mark.table.name}(#{quote_identifier(mark.table.identifier.name)})"
      clauses << "DEFERRABLE INITIALLY DEFERRED" if mark.deferrable?
      clauses.join(" ")
   end
   


end # Adapter
end # GenericSQL
end # Adapters
end # Schemaform
