#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2002 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================



class Class
   
   #
   # A convenience wrapper for new() that calls your block with the 
   # new instance.  For obvious reasons, can't be used with initializers
   # that expect a block.

   def create( *args )
      instance = self.send( "new", *args )
      if block_given? then
         yield( instance )
      end
      return instance
   end

end
