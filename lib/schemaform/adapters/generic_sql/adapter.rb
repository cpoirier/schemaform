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


#
# Base class and primary API for a database adapter. In general, there will be one Adapter
# instance for each physically distinct database attached to the system.

module Schemaform
module Adapters
module GenericSQL
class Adapter < Adapters::Adapter

   attr_reader :type_manager
   
   
   def print_to( printer )
      super do
         printer.label("Tables") do
            @tables.each do |table|
               printer.print(table.to_sql_create(name_width, type_width))
            end
         end
      end
   end
   
   
   #
   # Called by the Runtime system to install/upgrade schemas into the database.
   
   def install( schema )
      schema_name = schema.name.to_s.identifier_case
      
      transact do |connection|
         connection.execute(@schemas_table.render_sql_create(0, 0, true))
      end
      
      transact do |connection|
         installed_version = connection.retrieve_value("version", 0, @version_query, schema_name)
         if installed_version == 0 then            
            map(schema)
            
            fail_todo()
            
            
            @adapter.lay_out(schema).tables.each do |table|
               table.install(connection)
            end
            @versions[schema.name] = self.versions_table[schema_name, connection] = 1
         elsif installed_version < schema.version then
            fail "no version upgrade support yet"
         else
            fail_todo()
            
            @adapter.lay_out(schema)
         end
      end
   end
   

   #
   # Builds an appropriate Map::Node on the specified Model object. Override this if you customize
   # the base Map classes.
   
   def map( model )
      case model
      when Model::Schema
         Map::Schema.new(self, model)
      when Model::Entity
         Map::Entity.new(self, model)
      end
   end
   

   #
   # Defines a new table and calls your block to fill it in.
   
   def define_table( name, or_return_existing = false )
      name_string = name.to_s

      @monitor.synchronize do 
         if @tables.member?(name_string) then
            assert(or_return_existing, "cannot create duplicate table [#{name_s}]")
         else
            build_table(name).use do |table|
               yield(table)
               @tables.register(table, name_string)
            end
         end
      end
      
      @tables[name_string]
   end   
   
   
   
   
   # =======================================================================================
   #                                   Object Instantiation
   # =======================================================================================
   
   def build_query( relation )
      Query.new(relation)
   end

   def build_table( name )
      Table.new(self, name)
   end
   
   def build_name( *parts )
      Name.new(parts, @separator)
   end
   
   def build_internal_name( *parts )
      parts << sprintf(@internal_format, parts.pop)
      build_name(parts)
   end
   
   def build_present_name( *parts )
      parts << sprinf(@present_format, parts.pop)
      build_name(parts)
   end
   
   


protected
   def initialize( address, configuration = {} )
      super(address)

      @type_manager = TypeManager.new(self)
      @tables       = TableRegistry.new()    # name => Table
      @schema_maps  = {}                     # Schemaform::Model::Schema => SchemaMap
      @entity_maps  = {}                     # Schemaform::Model::Entity => EntityMap      
      @query_plans  = {}                     # Language::Placeholder => QueryPlan
      
      @schemas_table = define_table("schemas", true) do |table|
         table.define_field(:name   , type_manager().text_type(60) , table.build_primary_key_mark())
         table.define_field(:version, type_manager().integer_type())
      end
      
      @version_query   = @schemas_table.as_query.where(:name => []).select(:version)
      @separator       = configuration.fetch(:separator      , "__" )
      @internal_format = configuration.fetch(:internal_format, "$%s")
      @present_format  = configuration.fetch(:present_format , "%s?")
   end
   
   
   

   # Not sure what this does any more. Breaks the run-time-settable debug mode, so hopefully it's vestigial.
   #
   # if Schemaform.debug_mode? then
   #    def dispatch( method, determinant, *args, &block )
   #       begin
   #          send_specialized(method, determinant, *args, &block)
   #       rescue Baseline::SpecializationFailure => e
   #          Schemaform.log.dump(determinant, "DETERMINANT: ") if e.data[:determinant].object_id === determinant.object_id
   #          raise
   #       end
   #    end
   # else
   #    alias dispatch send_specialized
   # end

   alias dispatch send_specialized


   class TableRegistry < Registry
      
      def name_width()
         members.collect{|table| table.fields.name_width}.max()
      end
      
      def type_width()
         members.collect{|table| table.fields.type_width}.max()
      end
   end

end # Adapter
end # GenericSQL
end # Adapters
end # Schemaform

["query_parts", "map"].each do |subdir|
   Dir[Schemaform.locate("#{subdir}/*.rb")].each{|path| require path}
end

