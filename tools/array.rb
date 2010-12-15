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
   
   def exist?()
      !empty?
   end
   
   
   #
   # inject()
   #  - calls the block for each element, passing in the last value generated to each next item
   #  - returns the final value

   def inject( seed ) 
      each() do |element|
         result = yield( seed, element )
         next if result.nil?
         seed = result
      end
      return seed
   end
   
   
   #
   # select()
   #  - returns an array containing only those elements for which your block returns true
   
   def select( &proc )
      selected = []
      
      if proc.arity == 2 then
         each() do |index, element|
            selected << element if yield( index, element )
         end
      else
         each() do |element|
            selected << element if yield(element)
         end
      end
      
      return selected
   end
   
   
   #
   # select_first()
   #  - returns the first element for which your block returns true
   
   def select_first()
      each() do |element|
         return element if yield(element)
      end
      return nil
   end
   
        
   #
   # group()
   #  - returns several arrays, depending on the index your block returns
   #  - also handles true/false as indices 0/1 (yes, the reverse of the numerical conversion)
   
   def group( &proc )
      groups = []
      
      if proc.arity == 2 then
         each() do |index, element|
            group_index = yield(index, element)
            groups.accumulate( group_index.is_an?(Integer) ? group_index : (group_index ? 0 : 1), element )
         end
      else
         each() do |element|
            group_index = yield(element)
            groups.accumulate( group_index.is_an?(Integer) ? group_index : (group_index ? 0 : 1), element )
         end
      end
      
      return groups
   end
   
   
   #
   # remove_if()
   #  - just like delete_if(), except it returns an array of the deleted elements
   
   def remove_if()
      removed = []
      
      delete_if() do |element|
         if yield(element) then
            removed << element
            true
         else
            false
         end
      end
      
      return removed
   end
   
   
   #
   # accumulate()
   #  - appends your value to a list at the specified index
   #  - creates the array if not present
   
   def accumulate( key, value )
      if self[key].nil? then
         self[key] = []
      elsif !self[key].is_an?(Array) then
         self[key] = [self[key]]
      end

      self[key] << value
   end
   
   
   #
   # subsets()
   #  - treating this list as a set, returns all possible subsets
   #  - by way of definitions, sets have no intended order and no duplicate elements
   
   def subsets( pretty = true )
      set     = self.uniq
      subsets = [ [] ]
      until set.empty?
         work_point = [set.shift]
         work_queue = subsets.dup
         until work_queue.empty?
            subsets.unshift work_queue.shift + work_point
         end
         
      end
      
      subsets.sort!{|lhs, rhs| rhs.length == lhs.length ? lhs <=> rhs : rhs.length <=> lhs.length } if pretty

      return subsets
   end
   
   
   #
   # to_hash( )
   #  - converts the elements of this array to keys in a hash and returns it
   #  - the item itself will be used as value if the value you specify is :value_is_element
   #  - if you supply a block, it will be used to obtain keys from the element
   
   def to_hash( value = nil )
      hash = {}
      
      self.each do |element|
         key = block_given? ? yield( element ) : element
         if value == :value_is_element then
            hash[key] = element
         else
            hash[key] = value
         end
      end
      
      return hash
   end
   
   
   #
   # merge()
   #  - equivalant to (a + b).uniq(), but uses hashes to make the operation faster
   
   def merge( rhs )
      index = {}
      self.each do |e|
         index[e] = true
      end
      rhs.each do |e|
         index[e] = true
      end
      
      return index.keys
   end
   
   
   #
   # in_segments()
   #  - returns an array of slices of this array
   
   def in_segments( length = 1 )
      segments = []
      (self.length / length).times do |i|
         segment = self.slice(i * length, length)
         yield( segment ) if block_given?
         segments << segment
      end
      return segments
   end
   
   
   #
   # rest()
   #  - returns all but the first element
   
   def rest()
      return self[1..-1]
   end
   
   
   
   # 
   # last()
   #  - returns the last element or nil
   
   def last()
      return self[-1]
   end
   
   
   #
   # all?()
   #  - returns true if your block returns true for all of the elements
   
   def all?( expect = true )
      matches = true
      each do |element|
         unless yield(element) == expect
            matches = false
            break
         end
      end
      
      return matches
   end
   
   
   #
   # any?()
   #  - returns true if your block returns true for any of the elements
   
   def any?( expect = true )
      matches = false
      each do |element|
         if yield(element) == expect then
            matches = true
            break
         end
      end
      
      return matches
   end


   #
   # to_a()
   
   def to_a()
      return self
   end
   
   
   #
   # collect_from()
   #  - converts some data structure into an array by simulating collect()
   
   def Array.collect_from( container, method = :each, *parameters )
      collection = []
      container.send( method, *parameters ) do |element|
         if block_given? then
            collection << yield(element)
         else 
            collection << element
         end
      end
      
      return collection
   end
   
   #
   # select_from()
   #  - converts some data structure into an array by simulating select()
   
   def Array.select_from( container, method = :each, *parameters )
      collection = []
      container.send( method, *parameters ) do |element|
         collection << element if yield(element)
      end
      
      return collection
   end
   
   
   
   #
   # Redefines each to offer an index if 2 paramters are accepted.

   alias ruby_each each

   def each( &proc )
      if proc.arity == 2 then
         index = 0
         ruby_each do |element|
            begin
               proc.call( index, element ) 
            rescue LocalJumpError
               break
            end
            index += 1
         end
      else
         ruby_each do |element|
            begin
               proc.call( element ) 
            rescue LocalJumpError
               break
            end
         end
      end
   end


   #
   # Calls your block for each element in the array, working
   # backwards.

   def each_reverse()
      (self.length-1).downto(0) do |index|
         yield(self[index])
      end
   end

   #
   # Calls your block for each element left in the array after
   # passing the specified index.  If your block takes two 
   # parameters, the first will be the index and the second the element.

   def each_after_index( index, &proc )
      i = -1

      if proc.arity == 2 then
         each() do |element|
            i += 1
            next if i <= index 
            begin
               proc.call( i, element ) 
            rescue LocalJumpError
               break
            end
         end
      else
         each() do |element|
            i += 1
            next if i <= index
            begin
               proc.call( element ) 
            rescue LocalJumpError
               break
            end
         end
      end
   end

   #
   # Call the block for each pair of elements in the array.

   def each_pair()
      pair = []
      ruby_each do |value|
         pair << value
         if pair.length == 2 then
            yield( *pair )
            pair.clear
         end
      end
   end
   
   #
   # Iterates this array and another in sync.
   
   def each_in_step( array )
      self.length.times do |i|
         yield( self[i], array[i] )
      end
   end
   
   def in_pairs( array )
      pairs = []
      self.each_in_step(array) do |a, b|
         pairs << [a, b]
      end
      
      return pairs
   end


   #
   # I never liked the perl names for these routines.  They are even 
   # worse in Ruby...

   alias append  push
   alias prepend unshift

   alias remove_head shift
   alias remove_tail pop

   alias add_head unshift
   alias add_tail push

   def top()
      return self[-1]
   end

   alias each_object each
   
   
   
end
