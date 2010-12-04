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


class Product
   
   attr_reader :name, :release, :copyright, :license, :system_directory, :install_directory
   
   def initialize( name, release, copyright, license )
      @name      = name
      @release   = release
      @copyright = copyright
      @license   = @@licenses.member?(license) ? @@licenses[license] : license
                  
      @install_directory = File.dirname(File.normalize_path($0))
      @system_directory  = File.normalize_path(File.dirname(File.dirname(File.expand_path(__FILE__))))
      @version           = (File.directory?("#{@system_directory}/.svn") && `which svnversion`.strip.length > 0) ? `svnversion -n "#{@system_directory}"`.split(":").pop : "$Revision: $".to_i
   end
   
   def descriptor()
      return "#{@name} #{@release} (build #{@version})"
   end
   
   
   def system_path( relative )
      return @system_directory + relative
   end
   
   def install_path( relative )
      return @install_directory + relative
   end
   
   def relative_path( relative )
      return File.script_path(relative, 1)
   end
   
   def relative_system_directory( absolute )
      return File.contract_path(absolute, @system_directory)
   end
   
   def relative_install_directory( absolute )
      return File.contract_path(absolute, @install_directory)
   end
   
   def in_development?()
      return @version.ends?("M")
   end
   
 private
    
   @@licenses = { :gpl2 => "GNU General Public License, version 2", :apache2 => "Apache License, version 2.0" }
end
