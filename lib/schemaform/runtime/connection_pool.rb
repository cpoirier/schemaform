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

require "monitor"


#
# A connection pool manager.

module Schemaform
module Runtime
class ConnectionPool

   def initialize( database, connection_parameters = [], properties = {} )
      @database              = database
      @connection_parameters = connection_parameters
      
      @in_use_connections    = []
      @idle_connections      = []
      @monitor               = Monitor.new()
      @semaphore             = ConditionVariable.new()
                             
      @max_connections       = 0
      @idle_max              = 0
      @idle_min              = 0
      @unused_timeout        = 0
      
      reconfigure( properties )
   end
   
   
   #
   # Issues a connection from the pool for your exclusive use.  Waits until one is available, if requested.
   
   def issue_connection( to, wait = false, maximum_wait = nil )
      @monitor.synchronize do 
         if wait then 
            timeout = nil
            fail_at = maximum_wait ? Time.now + maximum_wait : nil
            until has_idle_connections?
               if fail_at then
                  timeout = fail_at - Time.now()
                  break unless timeout > 0
               end
               
               @semaphore.wait( timeout ) 
            end
         end
         
         has_idle_connections? ? @idle_connections.shift.tap{|connection| connection.assign_to(to, @idle_takeback) } : nil
      end
   end
   
   
   #
   # Returns a connection to the to pool.  
   
   def take_back( connection )
      assert( connection.owner == self, "unable to accept the return of connection [#{connection.object_id}], as it is not owned by this pool" )
      @monitor.synchronize do
         unless connection.closed?
            connection.holder = nil
                        
            @idle_connections << connection
            @semaphore.signal if has_idle_connections?
         end
      end
   end
   
   
   #
   # Reconfigures any of :max_connections, :idle_max, and :idle_min.  Note that :max_connections
   # wins, in case of a conflict.
   
   def reconfigure( properties = {} )
      @monitor.synchronize do
         properties.each do |property, value|
            case property
            when :max_connections
               @max_connections = value
            when :idle_max
               @idle_max = value
            when :idle_min
               @idle_min = value
            when :unused_timeout 
               @unused_timeout = value
            end
         end
      
         enforce_limits()
      end
   end
   
   
protected

   #
   # Returns true if a connection is available.

   def has_idle_connections?()
      @monitor.synchronize do
         enforce_limits()
         kill_unused_connections(1) if @idle_connections.empty?
         !@idle_connections.empty?
      end      
   end


   #
   # Goes through the pool and discards any connections that have been forcibly closed.
   
   def clean_up()
      @monitor.synchronize do
         @in_use_connections.delete_if{ |connection| connection.closed? }
           @idle_connections.delete_if{ |connection| connection.closed? }
      end
   end
   

   #
   # Opens or closes connections as necessary to respect configured limits.  Won't forcibly
   # close any in-use connections.
   
   def enforce_limits()
      @monitor.synchronize do
         clean_up()
         
         over = under = 0
      
         if @max_connections > 0 then            
            over = @in_use_connections.count + @idle_connections.count - @max_connections
         end
      
         if @idle_maximum > 0 then
            over = [over, @idle_maximum - @idle_connections.count].max
         end
      
         if @idle_minimum > 0 then
            under = @idle_minimum - @idle_connections.count
         end
      
         if over > 0 then
            close_idle_connections( over )
         elsif under > 0 then
            open_connections( under )
         end
      end
   end


   #
   # Closes up to the specified numbe of idle connections.
   
   def close_idle_connections( count = 0 )
      @monitor.synchronize do
         count.times do
            break if @idle_connections.empty?
            @idle_connections.shift.instance_eval{ close() }
         end
      end
   end
   
   #
   # Opens the specified number of connections and adds them to the idle list.
   
   def open_connections( count = 0 )
      @monitor.synchronize do
         pool = self
         count.times do
            @idle_connections << @database.instance_eval{connect(pool, *@connection_parameters)}
         end
      end
   end
   
   #
   # Attempts to kill some number of allocated but unused connections (1, by default). 
   
   def kill_unused_connections( count = 1 )
      @monitor.synchronize do
         @in_use_connections.each do |connection|
            if connection.unused?() then
               connection.close()
               count = count - 1
               break if count <= 0
            end
         end
         
         cleanup()
      end
   end


end # ConnectionPool
end # Runtime
end # Schemaform