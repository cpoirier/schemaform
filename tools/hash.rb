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


class Hash
   
   alias ruby_get []
   attr_writer :default_type
   
   def []( key, type = @default_type )
      self[key] = type.new() unless type.nil? || self.member?(key)
      return self.ruby_get(key)
   end
   
   
   #
   # first()
   #  - given a list of keys, returns the value for the first found
   
   def first( *keys )
      keys.each do |key|
         if member?(key) then
            return self[key]
         end
      end
      
      return self.default
   end
   
   
   #
   # Adds a pair to the hash and returns the hash for chaining.
   
   def add( key, value )
      self[key] = value
      return self
   end
   
   
   #
   # accumulate()
   #  - appends your value to a list at the specified index
   #  - creates the array if not present
   
   def accumulate( key, value )
      if !self.member?(key) then
         self[key] = []
      elsif !self[key].is_an?(Array) then
         self[key] = [self[key]]
      end

      self[key] << value
   end
   
end
