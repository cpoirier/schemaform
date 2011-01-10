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


class Array
   
   #
   # A synomym for !empty?
   
   def exist?()
      !empty?
   end
   
   
   #
   # Pushes an element before calling your block, then pops it again before returning.
   
   def push_and_pop( element )
      result = nil
      
      begin
         push element
         result = yield()
      ensure
         pop
      end
      
      result
   end
   
   
   #
   # Appends your value to a list at the specified index, creating an array at that index
   # if not present.
   
   def accumulate( key, value )
      if self[key].nil? then
         self[key] = []
      elsif !self[key].is_an?(Array) then
         self[key] = [self[key]]
      end

      self[key] << value
   end
   
   
   #
   # Converts the elements of this array to keys in a hash and returns it.  The item itself will be used 
   # as value if the value you specify is :value_is_element.  If you supply a block, it will be used to 
   # obtain keys from the element.
   
   def to_hash( value = nil, iterator = :each )
      hash = {}
      
      send(iterator) do |*data|
         key = block_given? ? yield( *data ) : data.last
         if value == :value_is_element then
            hash[key] = data.last
         else
            hash[key] = value
         end
      end
      
      return hash
   end
   
   
   #
   # Returns all but the first element in this list.
   
   def rest()
      return self[1..-1]
   end
   
   
   # 
   # Returns the last element from this list, or nil.
   
   def last()
      return self[-1]
   end
   
   alias top last

   
end
