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
   
   def self.connect( address )
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
   # Schemas you will be working with, in the order of name precedence. 

   def transact( available_schemas )
      workspace = build_workspace(available_schemas)
      @adapter.transact do |connection|
         yield(Transaction.new(workspace, connection))
         warn_todo("validate transaction")
      end
   end


   
   
protected

   def versions_table()
      @control_tables[:versions]
   end


   def build_workspace( *schemas )
      workspace_name = Workspace.name(schemas)

      unless @workspaces.member?(workspace_name)
         schemas.each do |schema|
            upgrade_schema(schema)
         end
      end
      
      @workspaces[workspace_name] ||= Workspace.new(self, schemas)
   end

   
   def upgrade_schema( schema )
      return if @versions.fetch(schema.name, 0) >= schema.version
      @monitor.synchronize do
         @adapter.transact do |connection|
            schema_name = schema.name.to_s.identifier_case
            installed_version = self.versions_table[schema_name, connection]
            if installed_version == 0 then
               @adapter.lay_out(schema).tables.each do |table|
                  table.install(connection)
               end
               @versions[schema.name] = self.versions_table[schema_name, connection] = 1
            elsif installed_version < schema.version then
               fail "no version upgrade support yet"
            end
         end
      end
   end
   
   
   def upgrade_system()
      @adapter.connect do |connection|         
         @control_tables.each do |name, table|
            table.definition.install(connection)
         end
         
         version = self.versions_table[Schemaform::MasterIdentifier, connection]
         if version == 0 then
            self.versions_table[Schemaform::MasterIdentifier, connection] = 1
         elsif version > 1 then
            fail "database #{@adaptor.url} has been managed with a more recent version of Schemaform (#{version})"
         end
      end
   end


   
private
   def initialize( adapter )
      @adapter    = adapter
      @monitor    = Monitor.new()
      @workspaces = {}
      @versions   = {}

      #
      # Define the control tables.
      
      @control_tables = {}
      @control_schema = @adapter.define_schema(Schemaform::MasterIdentifier)
      @control_tables[:versions] = VersionTable.new(@control_schema, @adapter)
      
      # @adapter.instance_eval do
      #    .tap do |control_schema|
      #       
      #       # tables[:configuration] = control_schema.define_table(make_name(:configuration, Schemaform::MasterIdentifier)).tap do |table|               
      #       #    table.add_field field_class.new(table, :name , nil, text_field_type(50) )
      #       #    table.add_field field_class.new(table, :value, nil, text_field_type(200))
      #       # end
      # 
      #       # tables[:versions] = control_schema.define_table(make_name("versions", Schemaform::MasterIdentifier), "schema_id").tap do |table|
      #       #    table.add_field field_class.new(table, :name   , nil, text_field_type(60))
      #       #    table.add_field field_class.new(table, :version, nil, integer_field_type(1..1000000000))
      #       # end
      #    end
      # end
      
      upgrade_system()
   end

   @@monitor   = Monitor.new()
   @@databases = {} 
   
   
   class VersionTable
      include QualityAssurance
      
      def initialize(control_schema, adapter)
         @adapter = adapter
         @table = adapter.instance_eval do
            control_schema.define_master_table(adapter.build_name(Schemaform::MasterIdentifier, "versions"), "schema_id").tap do |table|
               table.define_field(:name   , adapter.type_manager.text_type(60) )
               table.define_field(:version, adapter.type_manager.integer_type())
            end
         end
         
         warn_once("using hardcoded queries until query builders are done")
         @getter   = "SELECT version FROM schemaform$versions WHERE name = ?"
         @updater  = "UPDATE schemaform$versions set version = ? WHERE name = ?"
         @inserter = "INSERT INTO schemaform$versions (name, version) VALUES (?, ?)"
      end
      
      def definition()
         @table
      end
      
      def []( name, connection = nil, default = 0 )      
         return @adapter.connect{|connection| value = self[name, connection]} if connection.nil?
         connection.retrieve_value(0, default, @getter, name).to_i
      end

      def []=( name, connection = nil, value = nil )
         value, connection = connection, value if value.nil?
         return @adapter.connect{|connection| self[name, connection, value]} if connection.nil?

         if connection.update(@updater, value, name) == 0 then
            connection.insert(@inserter, name, value)
         end

         value
      end
      
   end
   
end # Database
end # Runtime
end # Schemaform
