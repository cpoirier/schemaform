#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2009 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================


class FlagSet
   
   
   def initialize( all = false )
      @all   = all
      @flags = {}
   end
   
   
   def flag_all()
      @all = true
   end
   
   
   def flag( *names )
      @all = false
      names.flatten.each {|name| @flags[name] = true }
   end
   
   
   def flagged?( *names )
      return true if @all
      
      names.each do |name|
         return @flags.member?(name)
      end
   end
   
   def explicitly_flagged?( *names )
      return false if @all
      return flagged?( *names )
   end
   
   alias on? flagged?
   
end