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


require File.expand_path(File.dirname(__FILE__)) + "/schemaform/sundry/quality_assurance.rb"

#
# Provides the master entry points for the Schemaform system, allowing you to define schemas,
# connect them to databases, and generally do useful stuff, without having to understand the
# inner workings (or namespaces) of the library.

module Schemaform
   extend  QualityAssurance
   include QualityAssurance
   
   
   #
   # Returns the named Schema definition.
   
   def self.[]( name )
      @@schemas = {} unless defined?(@@schemas)
      @@schemas[name]
   end
   
   
   
   #
   # Creates a Schema and calls your block to fill it in (see Schema::DefinitionLanguage).

   def self.define( name, &block )
      load_all()
      @@schemas = {} unless defined?(@@schemas)
      Definitions::Schema.new( name, &block ).tap do |schema|
         @@schemas[name] = schema
      end
   end
   
   
   #
   # Connects your Schema to a Database in one step.  What you get back is a Connection, 
   # ready to go.
   
   def self.connect( schema, database_url, prefix = nil, user = nil, password = nil )
      map = Mapping::Map.build( schema, database_url )
      fail
      
      account  = user ? Runtime::Account.new( user, password ) : nil
      database = Runtime::Database.for( database_url, account )
      coupling = database.couple_with( schema, "sqlite://cms.rb", "cms", account )
      coupling.connect( account )
   end
   
   
   # ==========================================================================================
   #                                    Environment Configuration
   # ==========================================================================================

   #
   # Disables checks for the entire Schemaform environment.  This is generally a good idea for 
   # production code, as checks can be quite expensive.  Note that this is a global setting, 
   # and can't be re-enabled once disabled.  For maximum cost savings, call this before you use 
   # any other Schemaform APIs (or require any other Schemaform files).

   def self.disable_checks()
      QualityAssurance.disable_checks()
   end


   #
   # Disables warnings for the entire Schemaform environment.
   
   def self.disable_warnings()
      QualityAssurance.disable_warnings()
   end



   # ==========================================================================================
   #                                      Operational Support
   # ==========================================================================================

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

         assert( !stack.empty?, "caller stack doesn't seem to show context file, which is needed for Schemaform.locate()" )

         trace_line  = stack.shift
         script_path = trace_line.split(":")[0]
         path = File.expand_path(path, File.dirname(File.expand_path(script_path, Dir.pwd())))
      end

      return path
   end
   
   
   #
   # Associates a TypeConstraint with a StorableType for use when defining types.  The constraint
   # must be registered before you attempt to use it in a Schema definition.  
   
   def self.define_type_constraint( name, type_class, constraint_class )
      load_all()
      Definitions::Schema.define_type_constraint( name, type_class, constraint_class )
   end

   
   #
   # Returns the time at which the system was started.
   
   def self.epoch()
      @@epoch
   end
   
   @@epoch = Time.now()
      
      
private
      
   #
   # Loads all Schemaform code into memory.
   
   def self.load_all()
      require locate("schemaform/sundry.rb"     )
      require locate("schemaform/definition.rb" )
      require locate("schemaform/expressions.rb")
      require locate("schemaform/mapping.rb"    )
      require locate("schemaform/runtime.rb"    )
   end
   
   
end # Schemaform


