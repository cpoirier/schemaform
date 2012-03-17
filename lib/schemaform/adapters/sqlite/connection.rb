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

require 'sqlite3'


module Schemaform
module Adapters
module SQLite
class Connection < GenericSQL::Connection
   
   def initialize( adapter )
      @adapter = adapter
      @api     = ::SQLite3::Database.new(@adapter.path)
   end
   
   
   def close()
      @api.close()
   end
   
   
   def transact()
      if @api.transaction_active? then
         yield
      else
         @api.transaction do
            yield
         end
      end
   end
   
   
   def retrieve( sql, *parameters )
      count = 0
      isolate(sql) do
         @api.execute(sql, *parameters) do |row|
            count += 1
            yield(row) if block_given?
         end      
      end
      return count
   end


   def insert( sql, *parameters )
      isolate(sql) do
         @api.execute(sql, *parameters)
         return @api.last_insert_row_id()
      end
   end

   def update( sql, *parameters )
      isolate(sql) do
         @api.execute(sql, *parameters)
         return @api.changes()
      end
   end
   
   def execute( sql )
      isolate(sql) do
         @api.execute(sql)
      end
   end
   
   
   
   def isolate(sql)
      begin
         debug(sql)
         yield
      rescue ::SQLite3::SQLException => e
         raise Error.new(nil, e)
      end
   end


end # Connection
end # GenericSQL
end # Adapters
end # Schemaform
