#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2007-2008 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================

   INFINITY = 1000000000

   def max( a, b )
      a > b ? a : b
   end

   def min( a, b )
      a < b ? a : b
   end

   def once()
      yield()
   end

   def forever()
      while true
         yield()
      end
   end
   
   def asc( string )
      return string[0]
   end

   def chr( code )
      if code.nil? then
         return nil
      else
         return code.chr
      end
   end

   def ignore_errors( *error_classes )
      begin
         yield()
      rescue Exception => e
         raise e unless error_classes.empty? or error_classes.member?(e.class)
         return false
      end
      
      return true
   end
   
   def with_context_variables( pairs = {} )
      old = pairs.keys.each{ |name| Thread.current[name] }
      begin
         pairs.each{ |name, value| Thread.current[name] = value }
         yield( )
      ensure
         old.each{ |name, value| Thread.current[name] = value }
      end      
   end
   
   def with_context_variable( name, value )
      old = Thread.current[name]
      begin
         Thread.current[name] = value
         yield()
      ensure
         Thread.current[name] = old
      end
   end
   
   def context_variable( name )
      return Thread.current[name]
   end
   
   
   #
   # Returns the first of values that is non nil.

   def whichever_exists( *values )
      value = whichever( *values )
      raise "whichever() did not find an existing value" if value.nil?
      return value
   end

   def whichever( *values )
      values.each do |value|
         return value if value.exists?
      end
   end

   #
   # Returns the supplied value or an empty array

   def array( array )
      if array.nil? then
         return []
      else
         return array
      end
   end




   
   

   

