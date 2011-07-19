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


#
# Base class and primary API for a database adapter. In general, there will be one Adapter
# instance for each physically distinct database attached to the system.

module Schemaform
module Adapters
module Generic
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
      fail_unless_overridden self, :url_for
   end
   
   #
   # Returns a connection to the underlying database. Individual adapters may implement
   # connection pooling, at their option.
   
   def connect()
      fail_unless_overridden self, :connect
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
      fail_unless_overridden self, :connect
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
   

   attr_reader :address, :type_manager, :schema_class, :table_class, :field_class, :separator
   
   def url()
      @address.url
   end
   
   def build_name( *components )
      Name.build(*components)
   end

protected
   def initialize( address, overrides = {} )
      @address      = address
      @schemas      = {}                # Definition => adapted Schema
      @monitor      = Monitor.new()

      @type_manager = overrides.fetch(:type_manager_class, TypeManager).new(self)
      @schema_class = overrides.fetch(:schema_class      , Schema     )
      @table_class  = overrides.fetch(:table_class       , Table      )
      @field_class  = overrides.fetch(:field_class       , Field      )
      @separator    = overrides.fetch(:separator         , "$"        )
   end

   @@monitor  = Monitor.new()
   @@adapters = {}



end # Adapter
end # Generic
end # Adapters
end # Schemaform

Dir[Schemaform.locate("builders/*.rb")].each{|path| require path}

