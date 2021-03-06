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
# The base class for DBMS-specific connection interfaces.

module Schemaform
module Adapters
class Connection
   include QualityAssurance
   extend  QualityAssurance
   
   
   def initialize( adapter )
      @adapter = adapter      
   end
   
   attr_reader :adapter
   
   def close()
   end

   def transact()
      fail_unless_overridden
   end
   
   def retrieve( sql, *parameters )
      fail_unless_overridden
   end

   def insert( sql, *parameters )
      fail_unless_overridden
   end

   def update( sql, *parameters )
      fail_unless_overridden
   end
   
   def execute( sql, *parameters )
      fail_unless_overridden
   end
   
   def escape_string( string )        ; @adapter.escape_string(string)        ; end
   def quote_string( string )         ; @adapter.quote_string(string)         ; end
   def quote_identifier( identifier ) ; @adapter.quote_identifier(identifier) ; end
   
   def retrieve_value( field, default, sql, *parameters )
      value = default
      retrieve(sql, *parameters) do |row|
         value = row[field]
         break
      end
      
      value
   end
      
   def retrieve_row( sql, *parameters )
      retrieve(sql, *parameters) do |row|
         return row
      end
      nil
   end   

   
   def retrieve_exists?( sql, *parameters )
      retrieve(sql, *parameters) do |row|
        return true
      end
      
      false
   end


end # Connection
end # Adapters
end # Schemaform
