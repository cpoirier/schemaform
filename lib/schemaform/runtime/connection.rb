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
   
   def initialize( database, configuration = {} )
      @database    = database
      @read_only   = !!configuration.delete(:read_only)
      @sequel      = Sequel.connect(database.url, configuration)
      @transaction = nil
   end
   
   attr_reader :read_only


   #
   # Calls your block with a transaction object against which you can do work. Note that transactions
   # are thread-local, due to the way the underlying Sequel library works.
   
   def transaction()
      outermost = false
      begin
         @database.monitor.synchronize do
            if @transaction.nil? then
               @transaction = Transaction.new(self)
               outermost    = true
            elsif @transaction.owner != Thread.current then
               fail "cannot use transaction from thread #{Thread.current}, as it belongs to thread #{@transaction.owner}"
            end
         end

         @sequel.transaction(:isolation => (@read_only ? :committed : :serializable)) do
            yield(@transaction)
         end
      ensure
         if outermost then
            begin
               @transaction.rollback
            ensure
               @transaction = nil
            end
         end
      end
   end



end # Connection
end # Runtime
end # Schemaform
