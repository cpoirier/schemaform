#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2010 Chris Poirier
# [License]   Licensed under the Apache License, Version 2.0 (the "License");
#             you may not use this file except in compliance with the License.
#             You may obtain a copy of the License at
#             
#                 http://www.apache.org/licenses/LICENSE-2.0
#             
#             Unless required by applicable law or agreed to in writing, software
#             distributed under the License is distributed on an "AS IS" BASIS,
#             WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#             See the License for the specific language governing permissions and
#             limitations under the License.
# =============================================================================================


require File.expand_path(File.dirname(__FILE__)) + "/schemaform/quality_assurance.rb"

#
# Provides the master entry points for the Schemaform system, allowing you to define schemas,
# connect them to databases, and generally do useful stuff, without having to understand the
# inner workings (or namespaces) of the library.

module Schemaform
   self.extend QualityAssurance
   
   
   #
   # Defines a schema and calls your block to fill it in.  With this method, your
   # block can treat the Schema::DefinitionLanguage as a DSL.

   def self.define( name, &block )
      Model::Schema.define( name, &block )
   end
   
   
   #
   # Calculates the absolute path to a file within the Schemaform system.  For paths beginning
   # "schemaform/", calculation is relative to the schemaform home directory, unless 
   # allow_from_root is cleared.  Otherwise, the path is calculated relative the caller's directory.
   
   def self.locate( path, allow_from_root = true )
      if allow_from_root && path[0..("schemaform/".length - 1)] == "schemaform/" then
         path = File.expand_path(path, File.dirname(__FILE__))
      else

         #
         # Figure out the file path of the script in which we were called.  Note that MacRuby has 
         # an extra level in the stack, compared to standard Ruby.  It costs a little more, but 
         # we'll search for "require" and step up one level from there.

         stack = caller(0)
         until stack.empty?
            line = stack.shift
            break if line =~ /locate.$/
         end

         assert( !stack.empty?, "caller stack doesn't seem to show context file, which is needed for Schemaform.require()" )

         trace_line  = stack.shift
         script_path = trace_line.split(":")[0]
         path = File.expand_path(path, File.dirname(File.expand_path(script_path, Dir.pwd())))
      end

      return path
   end
   
end # Schemaform


require Schemaform.locate("schemaform/ruby_extensions.rb")
require Schemaform.locate("schemaform/model/schema.rb")
