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

require 'monitor'


#
# Represents a single physical database within the system.

module Schemaform
module Runtime
class Database
   include QualityAssurance
   extend QualityAssurance
   
   attr_reader :url, :adapter, :connections, :master_account
   
   def read_only_connections()
      @read_only_connections || @connections
   end
   
   
   #
   # Returns the (global) Database object for the specified database URL.  The URL will be passed to the
   # Sequel library as a connection string, but must not contain account credentials or any other parameters,
   # due to the way Schemaform uses the Sequel library.  You must also provide a master account for use in 
   # maintaining the schema within the database.  It should have full privileges in the database.  It will
   # additionally be used as the default account for downstream objects (Couplings and Connections).
   
   def self.for( connection_string, configuration = {} )
      url = connection_string.split("?").shift
      key = url.downcase
      
      @@monitor.synchronize do
         if @@databases.member?(key) then
            @@databases[key].configure( configuration )
         else
            @@databases[key] = new( connection_string, configuration )
         end
      end
      
      @@databases[key]
   end
   
      
   #
   # Sets configuration parameters on the Database.
   
   def configure( configuration = {} )
      if configuration.member?(:connection_pool) then
         @connections.reconfigure( configuration[:connection_pool] ) 
      end
      
      if configuration.member?(:read_only_connection_pool) then
         @read_only_connections = ConnectionPool.new( self, [true] ) if @read_only_connections.nil?
         @read_only_connections.reconfigure( configuration[:read_only_connection_pool] )
      end
   end
   
   
private
   def initialize( connection_string, properties = {} )
      @connection_string     = connection_string      
      @connections           = ConnectionPool.new( self, [] )
      @read_only_connections = nil

      configure( properties )
   end

   @@monitor   = Monitor.new()
   @@databases = {} 
   
   def connect( owner, read_only = false )
      Connection.new( owner, @connection_string, read_only )
   end

end # Database
end # Runtime
end # Schemaform