#!/usr/bin/env ruby
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
      
      block_given? ? yield(@@databases[adapter.url]) : @@databases[adapter.url]
   end
   
   
   #
   # Provides a context in which your block can do work in the database. You must specify the
   # Schemas you will be working with, in the order of name precedence. 

   def transact_with( *available_schemas )
      workspace = build_workspace(available_schemas)
      @adapter.transact do |connection|
         yield(Transaction.new(workspace, connection))
         warn_todo("validate transaction")
      end
   end


   
   
protected

   def build_workspace( schemas )
      if schemas.length == 1 and schemas[0].is_a?(Workspace) then
         assert(schemas[0].database == self, "you can only pass a Workspace if it is from this Database" )
         return schemas[0] 
      end
      
      workspace_name = Workspace.name(schemas)

      unless @workspaces.member?(workspace_name)
         schemas.each do |schema|
            @adapter.install(schema)
         end
      end
      
      @workspaces[workspace_name] ||= Workspace.new(self, schemas)
   end

   
   def upgrade_schema( schema )
      warn_once("this should probably move to the adapter")
      return if @versions.fetch(schema.name, 0) >= schema.version
      @adapter.upgrade(schema)
   end
   
   
   
private
   def initialize( adapter )
      @adapter    = adapter
      @monitor    = Monitor.new()
      @workspaces = {}
   end

   @@monitor   = Monitor.new()
   @@databases = {} 
   
   
end # Database
end # Runtime
end # Schemaform
