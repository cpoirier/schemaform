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
   
   attr_reader :connection_string
   
   
   #
   # Returns the (global) Database object for the specified database URL.  The URL will be passed to the
   # Sequel library as a connection string.
   
   def self.connect( connection_string, configuration = {} )
      assert( connection_string !~ /@/, "the user@ connection string syntax is not compatible with Schemaform; please use the paramter format" )
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
   # Begins a transaction, in which you can do work.  You cannot do Schemaform work without one.
   # Note that transactions are thread-local -- you cannot share a single transaction between 
   # multiple threads, due to the way the Sequel library works.
   
   def transaction()
      thread    = Thread.current
      handle    = @transaction_handles.fetch( thread, nil )
      outermost = handle.nil?

      begin
         @sequel_database.transaction do |connection|
            if outermost then
               @transaction_handles[thread] = handle = TransactionHandle.new( self, connection )
            end
            
            yield( handle )
            
            if outermost then
               warn_once( "TODO: deal with transaction constraint checks" )
            end
         end
      ensure
         if outermost then
            handle.close()
            @transaction_handles[thread] = nil
         end
      end
   end
   
   
   #
   # Returns the connected Schema for the specified schema name.  The Schema must already be
   # defined.
   
   def []( name, prefix = nil )
      @connected_schemas[name] = {} unless @connected_schema.member?(name)
      @connected_schemas[name][prefix] = ConnectedSchema.build( self, Definitions::Schema[name] ) unless @connected_schema[name].member?(prefix)
      @connected_schemas[name][prefix]
   end
   
      
   #
   # Sets configuration parameters on the Database.
   
   def configure( configuration = {} )
   end
   
   
private
   def initialize( connection_string, properties = {} )
      @connection_string   = connection_string      
      @sequel_database     = Sequel.connect( connection_string, :test => true )
      @connected_schemas   = {}      
      @transaction_handles = {}
      configure( properties )
   end

   @@monitor   = Monitor.new()
   @@databases = {} 
   
end # Database
end # Runtime
end # Schemaform