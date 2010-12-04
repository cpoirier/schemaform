#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2004-2005 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================


class File

   #
   # Returns an absolute path calculated relative to the caller's file path.
   
   def File.script_path( path, extra_levels = 0 )

      #
      # MacRuby has an extra level in the stack, over that from standard Ruby.  It costs 
      # a little more, but we'll search for script_path and step up one level from there.
      
      stack = caller(0)
      until stack.empty?
         line = stack.shift
         break if line =~ /script_path/
      end
      
      extra_levels.times do
         stack.shift
      end
      
      assert( !stack.empty?, "caller stack doesn't seem to show context file, which is needed for File.script_path" )
      
      trace_line  = stack.shift
      relative_to = File.normalize_path(File.dirname(trace_line.split(":")[0]))
      return File.normalize_path(relative_to + path)
   end


   #
   # Checks if the path is to a directory or a file, and returns the appropriate path string.  Directories will always have a 
   # trailing slash.  If you pass nil for relative_to, path is not expanded.

   def File.normalize_path( path, relative_to=Dir.pwd() )
      expanded = (relative_to.nil? ? path : File.expand_path(path, relative_to))

      if File.directory?( expanded ) then
         return Dir.normalize_path( expanded, nil )
      else
         return expanded
      end
   end


   #
   # An analogue to File.expand_path(), returns a relative path, if path is inside relative_to, or within max_back directories
   # above it.

   File::UP_ONE_DIRECTORY_AFTER  = File::Separator + ".."
   File::UP_ONE_DIRECTORY_BEFORE = ".." + File::Separator

   def File.contract_path( path, relative_to=Dir.pwd(), max_back = 3 )

      relative_to = Dir.normalize_path( relative_to )
      normalized  = File.normalize_path( path, relative_to )

      levels_back = 0
      0.upto(max_back) do |level|

         current = File.expand_path( relative_to + (File::UP_ONE_DIRECTORY_AFTER * level) )
         current = File.normalize_path( current, nil )

         if normalized.begins?(current) then
            normalized  = normalized[current.length..-1]
            levels_back = level
         end
      end

      return (File::UP_ONE_DIRECTORY_BEFORE * levels_back) + normalized

   end


   #
   # Returns true if the path is absolute.  

   def File.absolute?( path )
      nyi("windows support") if RUBY_PLATFORM.contains?("win")
      return path.begins(File::Separator)
   end

end  # File

