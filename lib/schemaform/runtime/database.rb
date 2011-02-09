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
   
   attr_reader   :url, :adapter
   attr_accessor :master_account
   
   
   #
   # Couples the Database with a Schema for use.  You can couple multiple copies of the same Schema
   # to one Database, if you use a different name prefix for each.  Once you have a Coupling, you can 
   # connect() it any number of times to provide separate transaction scopes (and user credentials).
   
   def couple_with( schema, prefix = nil, coupling_account = nil )
      schema = schema.root
      prefix = nil if prefix.to_s == ""
      
      @couplings_monitor.synchronize do
         @couplings[schema.name] = {} unless @couplings.member?(schema.name)
         if @couplings[schema.name].member?(prefix) then
            @couplings[schema.name][prefix].coupling_account = coupling_account
         else
            @couplings[schema.name][prefix] = Coupling.new( self, schema, prefix, coupling_account )
         end
      end      
      
      @couplings[schema.name][prefix]
   end
   
   
   #
   # Returns the (global) Database object for the specified database URL.  The URL will be passed to the
   # Sequel library as a connection string, but must not contain account credentials or any other parameters,
   # due to the way Schemaform uses the Sequel library.  You must also provide a master account for use in 
   # maintaining the schema within the database.  It should have full privileges in the database.  It will
   # additionally be used as the default account for downstream objects (Couplings and Connections).
   
   def self.for( url, master_account )
      assert( url !~ /(\/\/[^\/@]+@)|\?/, "database URL cannot cantain a user name or other parameters" )
      
      @@monitor.synchronize do
         if @@databases.member?(url) then
            @@databases[url.downcase].master_account = master_account
         else
            @@databases[url.downcase] = new(url, master_account)
         end
      end
      
      @@databases[url.downcase]
   end
   
   
private
   def initialize( url, master_account )
      @url               = url      
      @master_account    = master_account
      @couplings         = {}
      @couplings_monitor = Monitor.new()
      @adapter           = Adapters.adaptor_for( url )
   end

   @@monitor   = Monitor.new()
   @@databases = {} 

end # Database
end # Runtime
end # Schemaform