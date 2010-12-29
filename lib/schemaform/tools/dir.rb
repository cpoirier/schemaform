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

require( File.dirname(File.expand_path(__FILE__)) + "/string.rb" )


class Dir

   #
   # File and Dir don't seem to have very good platform independent path manipuation code, and File.expand_path() isn't (IMHO) 
   # particularly consistent in the way trailing slashes are handled.  These routines return the directory path with a trailing 
   # slash.  If you pass nil for relative_to, path is not expanded first.

   def Dir.normalize_path( path, relative_to=Dir.pwd() )
      expanded = (relative_to.nil? ? path : File.expand_path(path, relative_to))
      return expanded + (expanded.ends?(File::Separator) ? "" : File::Separator)
   end

end
