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
# Base class and primary API for a database adapter. In general, there will be one Adapter
# instance for each physically distinct database attached to the system.

module Schemaform
module Adapters
class Adapter
   include QualityAssurance
   extend  QualityAssurance
      
   #
   # Builds or retrieves an Adapter for the specified coordinates and returns it.
   
   def self.build( coordinates )
      if address = address(coordinates) then
         @@monitor.synchronize do
            unless @@adapters.member?(address.url)
               @@adapters[address.url] = new(address)
            end
         end
         
         return @@adapters[address.url]
      end
   end


   #
   # Creates an Address for the coordinates.
   
   def self.address( coordinates )
      fail_unless_overridden
   end
   
   
   #
   # Returns a connection to the underlying database, or calls your block with the connection. 
   # Individual adapters may implement connection pooling, at their option.
   
   def connect()
      fail_unless_overridden
   end
   
   
   #
   # Similar to connect(), but wraps your block in a transaction.
   
   def transact()
      connect do |connection|
         connection.transact do
            yield(connection)
         end
      end
   end

   
   #
   # Escapes special characters in a string for inclusion in a query.
   
   def escape_string( string )
      fail_unless_overridden
   end
   
   
   #
   # Quotes a string for inclusion in a query.
   
   def quote_string( string )
      "'#{escape_string(string)}'"
   end
   
   
   #
   # Quotes an identifier for inclusion in a query.
   
   def quote_identifier( identifier )
      "\"#{identifier}\""
   end


   #
   # Returns the Monitor for this Adapter.
   
   attr_reader :monitor
   

   #
   # Returns the Address for this Adapter.
   
   attr_reader :address
   
   
   #
   # Returns just the URL of the Address for this Adapter.
   
   def url()
      @address.url
   end


   #
   # Prints the Adapter using the specified Printer.
   
   def print_to( printer )
      printer.label("#{self.class.namespace_module.unqualified_name} Adapter for #{@address.url}") do
         yield
      end
   end
      
      
   #
   # Called by the Runtime system to install/upgrade schemas into the database.
   
   def install( schema )
      fail_unless_overridden
   end
   
   
   

protected
   def initialize( address )
      @address = address
      @monitor = Monitor.new()
   end
   

   @@monitor  = Monitor.new()
   @@adapters = {}
   

end # Adapter
end # Adapters
end # Schemaform

