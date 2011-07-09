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
   
   attr_reader :monitor
   
   
   #
   # Returns the Database object for the specified database address information.
   
   def self.connect_to( address )
      adapter = Schemaform::Adapters[address]
      @@monitor.synchronize do
         unless @@databases.member?(adapter.url)
            @@databases[adapter.url] = new(adapter)
         end
      end
      
      @@databases[adapter.url]
   end
   
   
   #
   # Provides a context in which your block can do work in the database. You must specify the
   # Schemas (or PrefixedSchemas) you will be working with, in the order of name precedence. 

   def transact( available_schemas )
      workspace = (@workspaces[Workspace.name(available_schemas)] ||= Workspace.build(self, available_schemas))
      @adapter.transact do |connection|
         yield(Transaction.new(workspace, connection))
         warn_once("TODO: validate transaction")
      end
   end

   
   #
   # Registers a Schema with the database for use. Note that you can associate each Schema
   # (object) only once with a particular prefix. Runs migration immediately. 
   #
   # Be careful to do all association from a single thread. Assignment of default names is not
   # done until migration of the new schema is complete, and if you do association from multiple
   # threads, you may end up with random ordering.
   
   def register( schema, prefix = nil )

      #
      # First allocate a spot for the schema or fail (only one registration per schema).
      
      associated = false
      @monitor.synchronize do
         if @associated_schemas.member?(schema) then
            check{ fail "schema [#{schema.full_name}] is already registered with database [#{@url}] under prefix [#{@associated_schemas[schema]}]" }
         else
            @associated_schemas[schema] = @adapter.lay_out(schema, prefix)
            associated = true
         end
      end
      
      #
      # If we did the association, lay out the schema for use and ensure the physical schema is 
      # up-to-date. Finally, register the names for lookup.
      
      if associated then
         schema.upgrade(self, @associated_schemas[schema])
         
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
   
   
protected

   def build_workspace( schemas )
      workspace_name = Workspace.name(schemas)

      unless @workspaces.member?(workspace_name)
         schemas.each do |schema|
            upgrade_schema(schema)
         end
      end

      @workspaces[workspace_name] ||= Workspace.build(self, schemas)
   end

   
   def upgrade_schema( schema )
      return if @versions.fetch(schema.name, 0) >= schema.version
      @monitor.synchronize do
         current_version = @versions.fetch(schema.name, 0)
         if current_version == 0 then
            @adapter.transact do |connection|
               schema.install(connection)
            end
         else
            fail "no version upgrade support yet"
         end
      end
   end
   
   
   def upgrade_system( connection )
      
   end
   
   
   
private
   def initialize( adapter )
      @adapter    = adapter
      @monitor    = Monitor.new()
      @workspaces = {}
      @versions   = {}

      @master_tables = tables = {}
      @master_schema = @adapter.instance_eval do
         define_schema(Schemaform::MasterIdentifier).tap do |master_schema|
            tables[:configuration] = master_schema.define_table(make_name(:configuration, Schemaform::MasterIdentifier)).tap do |table|               
               table.add_field field_class.new(table, :name , nil, text_field_type(50) )
               table.add_field field_class.new(table, :value, nil, text_field_type(200))
            end
            
            tables[:versions] = master_schema.define_table(make_name("versions", Schemaform::MasterIdentifier), "schema_id").tap do |table|
               table.add_field field_class.new(table, :name   , nil, text_field_type(60))
               table.add_field field_class.new(table, :version, nil, integer_field_type(1..1000000000))
            end
         end
      end
      
      @adapter.connect do |connection|         
         @master_tables.each do |name, table|
            begin
               connection.query(table.to_sql_select("*", false))
            rescue 
               connection.execute(table.to_sql_create)
            end
         end
         
         configuration_table = @master_tables[:configuration]
         version_indicator   = "schemaform_version"
         
         version = connection.query_value(0, "0", configuration_table.to_sql_select(:value, :name => version_indicator)).to_i
         if version == 0 then
            connection.insert(configuration_table.to_sql_insert(:name => version_indicator, :value => 1))
         elsif version > 1 then
            fail "database #{@adaptor.url} has been managed with a more recent version of Schemaform (#{version})"
         end
      end
   end

   @@monitor   = Monitor.new()
   @@databases = {} 

   
end # Database
end # Runtime
end # Schemaform
