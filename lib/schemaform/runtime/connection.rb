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

require 'rubygems'
require 'sequel'


#
# Provides a query execution context for a database.  Be sure to set the idle_limit explicitly, 
# if you expect to leave the connection alone for a while, or the ConnectionPool may close it
# out from under you.  
#
# Note that, in Schemaform, it is absolutely, positively, 100% ILLEGAL to do any work in the 
# database (read or write) without a valid, explicit transaction.  If you attempt any action 
# without one, expect an AssertionFailure.
#
# Finally, as a rule, you should never have cause to directly execute a query against a connection: 
# that is what the Schemaform classes are for.

module Schemaform
module Runtime
class Connection
   
   attr_reader   :owner, :read_only, :idle_limit
   attr_accessor :holder

   def idle_limit=( seconds )
      @idle_limit = seconds
      @last_query = Time.now()
   end
   
   def closed?()
      !@connected
   end
   
   def unused?()
      Time.now() - @last_query > @idle_limit
   end
   
   def initialize( owner, connection_string, read_only = false )
      @owner        = owner
      @holder       = nil
      @read_only    = read_only
      @idle_limit   = 0
      @last_query   = Time.now()
      @sequel       = Sequel.connect( connection_string )
      @connected    = @sequel.exists?
      @transactions = 0
   end
   
   def assign_to( holder, idle_limit = 0 )
      @holder     = holder
      @idle_limit = idle_limit
      @last_query = Time.now()
   end
   
   def close()
      @sequel.disconnect()
      @connected = false
   end
   
   
   def transaction()
      @sequel.transaction( :isolation => @read_only ? :committed : :serializable ) do
         begin
            @transactions += 1
            yield
         ensure
            @transactions -= 1
         end
      end
   end
   


end # Connection
end # Runtime
end # Schemaform