#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2004-2010 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================



class IO

   def get_char()
      c = getc()
      return chr(c)
   end

   def unget_char( c )
      i = asc(c)
      ungetc(i)
   end

   def lookahead_char()
      c = get_char()
      unget_char(c)
      return c
   end

   def each_char()
      while c = get_char()
         yield( c )
      end
   end

   def skip()
      puts "\n"
   end

end

