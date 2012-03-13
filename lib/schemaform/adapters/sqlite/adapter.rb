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

require 'sqlite3'

#
# Walks a Schema to lay out structures in tables and fields.

module Schemaform
module Adapters
module SQLite
class Adapter < GenericSQL::Adapter
   
   def self.address( coordinates )
      if path = File.expand_path(coordinates.fetch(:path, nil)) then
         GenericSQL::Address.new("sqlite:#{path}", coordinates.update(:path => path))
      end
   end
   
   def connect()
      connection = Connection.new(self) 
      if block_given? then
         begin
            yield(connection)
         ensure 
            connection.close()
         end
      else
         connection
      end
   end
   
   attr_reader :path

   def escape_string( string )
      ::SQLite3::Database.quote(string)
   end

   def render_sql_create_table( table, name_width = 0, type_width = 0 )
      super.gsub("AUTOINCREMENT PRIMARY KEY", "PRIMARY KEY AUTOINCREMENT")
   end

   
protected
   def initialize( address, overrides = {})
      super(address, overrides)
      @path = address.path
   end
   
end # Adapter
end # SQLite
end # Adapters
end # Schemaform

Schemaform::Adapters.register(:sqlite, :SQLite)


