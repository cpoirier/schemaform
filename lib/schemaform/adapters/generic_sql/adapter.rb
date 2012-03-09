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


#
# Base class and primary API for a database adapter. In general, there will be one Adapter
# instance for each physically distinct database attached to the system.

module Schemaform
module Adapters
module GenericSQL
class Adapter
   include QualityAssurance
   extend  QualityAssurance
   
   
   #
   # Builds or retrieves an Adapter for the specified coordinates and returns it.
   
   def self.build( coordinates )
      if address = address(coordinates) then
         @@monitor.synchronize do
            unless @@adapters.member?(address.url)
               @@adapters[address.url] = new(address)
            end
         end
         
         return @@adapters[address.url]
      end
   end


   #
   # Creates an Address for the coordinates.
   
   def self.address( coordinates )
      fail_unless_overridden
   end
   
   #
   # Returns a connection to the underlying database, or calls your block with the connection. 
   # Individual adapters may implement connection pooling, at their option.
   
   def connect()
      fail_unless_overridden
   end
   
   
   #
   # Similar to connect(), but wraps your block in a transaction.
   
   def transact()
      connect do |connection|
         connection.transact do
            yield(connection)
         end
      end
   end

   
   #
   # Escapes special characters in a string for inclusion in a query.
   
   def escape_string( string )
      fail_unless_overridden
   end
   
   
   #
   # Quotes a string for inclusion in a query.
   
   def quote_string( string )
      "'#{escape_string(string)}'"
   end
   
   
   #
   # Quotes an identifier for inclusion in a query.
   
   def quote_identifier( identifier )
      "\"#{identifier}\""
   end
   

   attr_reader :address, :type_manager, :schema_class, :table_class, :field_class, :index_class, :separator, :schema_maps, :entity_maps
   
   def url()
      @address.url
   end
   
   def build_name( *components )
      Name.build(*components)
   end
   
   
   def define_table( *name )
      table_class.new(self, build_name(*name)).tap do |table|
         @tables.register(table)
         yield(table) if block_given?
      end
   end
   
   def print_to( printer )
      printer.label("#{self.class.namespace_module.unqualified_name} Adapter for #{@address.url}") do
         printer.label("Tables") do
            @tables.each do |table|
               printer.print(table.to_sql_create(name_width, type_width))
            end
         end
      end
   end
   

protected
   def initialize( address, overrides = {} )
      @address      = address
      @tables       = Registry.new()    # name => Table
      @schema_maps  = {}                # Schemaform::Schema => SchemaMap
      @entity_maps  = {}                # Schemaform::Schema::Entity => EntityMap      
      @query_plans  = {}                # Language::Placeholder => QueryPlan
      @monitor      = Monitor.new()
      @overrides    = overrides

      @type_manager = overrides.fetch(:type_manager_class, TypeManager).new(self)
      @table_class  = overrides.fetch(:table_class       , Table      )
      @field_class  = overrides.fetch(:field_class       , Field      )
      @index_class  = overrides.fetch(:index_class       , Index      )
      @separator    = overrides.fetch(:separator         , "$"        )
   end

   @@monitor  = Monitor.new()
   @@adapters = {}
   
   def name_width()
      @name_width ||= @tables.collect{|table| table.name_width}.max()
   end
   
   def type_width()
      @type_width ||= @tables.collect{|table| table.type_width}.max()
   end
      


   if Schemaform.in_development? then
      def dispatch( method, determinant, *args, &block )
         begin
            send_specialized(method, determinant, *args, &block)
         rescue Baseline::SpecializationFailure => e
            Printer.print(determinant, "DETERMINANT: ") if e.data[:determinant].object_id === determinant.object_id
            raise
         end
      end
   else
      alias dispatch send_specialized
   end
   

end # Adapter
end # GenericSQL
end # Adapters
end # Schemaform

["schema", "mapping", "queries"].each do |subdir|
   Dir[Schemaform.locate("#{subdir}/*.rb")].each{|path| require path}
end

