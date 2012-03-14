#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2012 Chris Poirier
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


require "rubygems"
require "sequel"
require "set"
require "baseline"


#
# Provides the master entry points for the Schemaform system, allowing you to define schemas,
# connect them to databases, and generally do useful stuff, without having to understand the
# inner workings (or namespaces) of the library.

module Schemaform
   QualityAssurance = Baseline::QualityAssurance
   extend  QualityAssurance
   include QualityAssurance
   
   MasterName       = "Schemaform"
   MasterVersion    = 1
   MasterIdentifier = MasterName.identifier_case
   

   @@locator = Baseline::ComponentLocator.new(__FILE__, 2)
   
   #
   # Returns the named Schema definition.
   
   def self.[]( name, version = nil )
      @@schemas[name][version]
   end


   #
   # Returns true if the named Schema is already defined.
   
   def self.defined?( name, version = nil )
      return false unless @@schemas.member?(name)
      @@schemas[name].member?(version)
   end
   
   
   #
   # Creates a Schema and calls your block to fill it in (see Schema::DefinitionLanguage).

   def self.define( name, version, &block )
      @@schemas.register(VersionSet.new(name)) unless @@schemas.member?(name)
      assert(!@@schemas[name].member?(version), "Schema #{name} version #{version} is already defined")
      
      Schema.new(name, version).use do |schema|
         @@schemas[name][version] = schema
         Language::SchemaDefinition.process(schema, &block)         
      end
   end
   
   
   #
   # Connects to a database. You will need to associate your schemas with the database_url before 
   # you will be able to use them (you can do that before or after connecting).
   
   def self.connect( address, &block )
      Runtime::Database.connect(address, &block)
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
      @@locator.locate( path, allow_from_root )
   end
   
   
   #
   # Associates a TypeConstraint with a StorableType for use when defining types.  The constraint
   # must be registered before you attempt to use it in a Schema definition.  
   
   def self.define_type_constraint( name, type_class, constraint_class )
      Definitions::Schema.define_type_constraint( name, type_class, constraint_class )
   end

   
   #
   # Returns the time at which the system was started.
   
   def self.epoch()
      @@epoch
   end
   
   @@epoch = Time.now()
   
   
   #
   # Returns true if Schemaform is running in debug mode.
   
   def self.debug_mode?()
      @@debug.stream.exists?
   end
   
   
   #
   # Returns the debug Printer.
   
   def self.debug()
      @@debug
   end
   
   
   #
   # (Re-)Initializes the debug Printer to the supplied stream. Setting it to nil disables 
   # debugging. If you pass a block, your block will be called with the new stream in place,
   # and the old one will be restored on completion.
   
   def self.debug_to( stream )
      old_stream = @@debug.stream
      @@debug = Printer.new(stream)

      if block_given? then
         begin
            yield
         ensure
            @@debug = Printer.new(old_stream)
         end
      end
   end
   

   #
   # Returns the log Printer.
   
   def self.log()
      @@log
   end
   
   
   #
   # (Re-)Initializes the log Printer to the supplied stream. If you pass a block, your blok will
   # b called with the new stream in place, and the old one will be restored on completion.
   
   def self.log_to( stream )
      old_stream = @@log.stream
      @@log = Printer.new(stream)
      
      if block_given? then
         begin
            yield
         ensure
            @@debug = Printer.new(old_stream)
         end
      end
   end
   
      
private
   
   require locate("schemaform/schema.rb")
   
   ["utilities", "language", "productions", "plan", "adapters", "runtime", "migration"].each do |directory|
      Dir[Schemaform.locate("schemaform/#{directory}/*.rb")].each do |path|
         require path
      end
   end
   
   @@schemas = Registry.new("Schemaform")
   @@log     = Printer.new(nil)
   @@debug   = Printer.new(nil)


end # Schemaform



