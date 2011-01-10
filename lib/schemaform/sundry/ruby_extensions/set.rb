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

require 'set'

class Set

   #
   # Returns a list of all possible subsets of the elements in this set.  By way of definitions,
   # sets have no intended order and no duplicate elements

   def subsets( pretty = true )
      set     = self.dup
      subsets = [ Set.new() ]
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

end
