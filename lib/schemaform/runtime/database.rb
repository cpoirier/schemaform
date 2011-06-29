#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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

require 'monitor'


#
# Represents a single physical database within the system. This is the master controller for
# the Runtime system -- everything starts here.

module Schemaform
module Runtime
class Database
   include QualityAssurance
   extend  QualityAssurance
   
   attr_reader :url, :monitor
   

   #
   # Returns the Database object for the specified database URL. The URL will be passed to the
   # Sequel library as a connection string. It must *never* contain account credentials or other
   # details that might change from use to use within the life of the process. Use configure() or
   # related API points for that stuff.
   
   def self.for_url( url )
      assert(url !~ /@/, "the user@ connection string syntax is not compatible with Schemaform; please use the paramter format")
      key = url.split("?").shift.downcase
      
      @@monitor.synchronize do
         if @@databases.member?(key) then
            check{assert(@@databases[key].url == url, "database [#{key}] does not match supplied URL", :requested_url => url, :existing_url => @@databases[key].url)}
         else
            @@databases[key] = new(url)
         end
      end
      
      @databases[key]
   end
   
   
   #
   # Associates a Schema with the database for use. Note that you can associate each Schema
   # (object) only once. Runs migration immediately. 
   #
   # Be careful to do all association from a single thread. Assignment of default names is not
   # done until migration of the new schema is complete, and if you do association from multiple
   # threads, you may end up with random ordering.
   
   def associate_schema( schema, prefix = nil )

      #
      # First allocate a spot for the schema or fail (only one registration per schema).
      
      associated = false
      @monitor.synchronize do
         if @associated_schemas.member?(schema) then
            check{ fail "schema [#{schema.full_name}] is already registered with database [#{@url}] under prefix [#{@associated_schemas[schema]}]" }
         else
            @associated_schemas[schema] = prefix
            associated = true
         end
      end
      
      #
      # If we did the association, ensure the schema is up-to-date, then register the names
      # for lookup. Note that the upgrade could take some arbitrary length of time, so, to 
      # ensure reliable assinand so
      # the names cou
      
      if associated then
         schema.upgrade(Sequel.connect(@url, migration_configuration), prefix)
         
         @monitor.synchronize do
            @by_schema_version_entity[schema.name] = {} unless @by_schema_version_entity.member?(schema.name)
            @by_schema_version_entity[schema.name][schema.version] = schema unless @by_schema_version_entity[schema.name].member?(schema.version)
            
            @by_schema_entity[schema.name] = schema unless @by_schema_entity.member?(schema.name)
         
            schema.entities.each do |entity|
               @by_entity[entity.name] = entity unless @by_entity.member?(entity.name)
            end
         end
      end
   end
   
   
   #
   # Connects do the Database with the specified configuration.
   
   def connect( configuration = {} )
      Connection.new(self, configuration)
   end


   #
   # Returns the Schema::Entity for the specified name vector:
   #    * entity_name
   #    * schema_name, entity_name
   #    * schema_name, schema_version, entity_name
   
   def []( *address )
      case address.length
      when 1
         @by_entity[address.shift]
      when 2
         @by_schema_entity[address.shift][address.shift]
      when 3
         @by_schema_version_entity[address.shift][address.shift][address.shift]
      else
         fail
      end
   end
   
   
private
   def initialize( url, migration_configuration )
      @url                      = url
      @migration_configuration  = migration_configuration
      @monitor                  = Monitor.new()
      @associated_schemas       = {}       # Schema => SchemaInfo
      @by_schema_version_entity = {}       # name => VersionSet
      @by_schema_entity         = {}       # name => Schema
      @by_entity                = {}       # name => Entity
   end

   @@monitor   = Monitor.new()
   @@databases = {} 

   
end # Database
end # Runtime
end # Schemaform
