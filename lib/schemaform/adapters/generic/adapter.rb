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
module Generic
class Adapter
   include QualityAssurance
   extend  QualityAssurance
   
   #
   # Builds or retrieves an Adapter for the specified coordinates and returns it.
   
   def self.build( coordinates )      
      fail_unless_overridden self, :build
   end


   #
   # Returns a connection to the underlying database. Individual adapters may implement
   # connection pooling, at their option.
   
   def connect()
      fail_unless_overridden self, :connect
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
      fail_unless_overridden self, :connect
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
   
   
   #
   # Lays out a Schema for use with the database.
   
   def lay_out( schema )
      @monitor.synchronize do
         unless @layouts.member?(schema)
            @layouts[schema] = lay_out_schema(schema)
         end
      end
      
      @layouts[schema]
   end
   
   def define_schema( name )
      schema_class().new(name, self)
   end
   
   
   attr_reader :url


   def schema_class()         ; Schema          ; end
   def table_class()          ; Table           ; end
   def field_class()          ; Field           ; end
   def reference_field_class  ; ReferenceField  ; end
   def identifier_field_class ; IdentifierField ; end
   def separator              ; "__"            ; end
   
   def name_for( schema, prefix = nil )
      prefix.to_s + schema.name.to_s.identifier_case
   end
   
   def lay_out_schema( schema, container = nil, prefix = nil )
      if schema.is_a?(Runtime::PrefixedSchema) then
         prefix = name_for(schema.schema, name_for(schema.prefix(separator()), prefix))
         schema = schema.schema
      else
         prefix = name_for(schema, prefix)
      end
      
      schema_class.new(schema, self).tap do |layout|
         names = {}

         #
         # Create the master tables first. We need them in place for references.

         schema.entities.each do |entity|
            layout.translations[entity.name] = table_name = make_name(entity.name.to_s.identifier_case, prefix)
            layout.define_table(table_name, entity.id, entity.has_base_entity? ? layout.tables[layout.translations[entity.base_entity.name]] : nil)
         end
         
         #
         # Now, fill them in.

         schema.entities.each do |entity|
            master_table = layout.tables[layout.translations[entity.name]]
            entity.heading.attributes.each do |attribute|
               next if attribute.name == entity.id
               next if entity.base_entity && entity.base_entity.declared_heading.attribute?(attribute.name)

               lay_out(attribute, master_table)
            end
         end
      end
   end
   
   def lay_out_element( element, container, prefix = nil )
      current_class = element.class
      while current_class
         assert(current_class != Schema::Element, "unsupported element class #{element.class.name}")
         specialized = current_class.specialize_method_name("lay_out")
         return self.send(specialized, element, container, prefix) if self.responds_to?(specialized)
         current_class = current_class.superclass
      end
   end
   
   def lay_out_entity( entity, container, prefix = nil )
      fail "this should have been handled in lay_out_schema"
   end

   def lay_out_tuple( tuple, container, prefix = nil )
      tuple.attributes.each do |attribute|
         lay_out(attribute, container, prefix)
      end      
   end
   
   def lay_out_attribute( attribute, container, prefix = nil )
      lay_out(attribute.type, container, make_name(attribute.name, prefix))
   end
   
   def lay_out_optional_attribute( attribute, container, prefix = nil )
      lay_out_attribute(attribute, container, prefix)
      container.add_field field_class.new(container, make_name("present", make_name(attribute.name, prefix)), nil, boolean_field_type, "not null")
   end

   def lay_out_volatile_attribute( attribute, container, prefix = nil )
      nil
   end
   

   def lay_out_type( type, container, name = nil )
      fail "no lay_out support for #{type.class.name}"
   end
   
   def lay_out_reference_type( type, container, name = nil )
      warn_once("TODO: reference field null/default handling")
      
      
      if (referenced_table_name = container.schema.translations[type.entity_name]) && (referenced_table = container.schema.tables[referenced_table_name]) then
         container.add_field reference_field_class.new(container, name, referenced_table, true, false)
      else
         fail "reference to un-laid-out table -- how is this possible?"
      end
   end

   def lay_out_identifier_type( type, container, name = nil )
      if (referenced_table_name = container.schema.translations[type.entity_name]) && (referenced_table = container.schema.tables[referenced_table_name]) then
         container.add_field reference_field_class.new(container, name, referenced_table, false, true)
      else
         fail
      end
   end

   def lay_out_scalar_type( type, container, name = nil )
      container.add_field field_class.new(container, name, type, scalar_field_type(type))
   end

   def lay_out_tuple_type( type, container, prefix = nil )
      lay_out(type.tuple, container, prefix)
   end
   
   def lay_out_collection_type( type, container, prefix = nil )
      container.define_table(prefix).tap do |table|
         table.add_field reference_field_class.new(table, container.id_field.name, container, false, true)
         if type.member_type.is_a?(Schemaform::Schema::ReferenceType) then
            referenced_name = type.member_type.referenced_entity.id
            referenced_name = make_name(referenced_name, prefix) if container.id_field.name == referenced_name
            lay_out(type.member_type, table, referenced_name)
         else 
            lay_out(type.member_type, table, prefix)
         end
      end
   end
   
   def lay_out_list_type( type, container, prefix = nil )
      lay_out_collection_type(type, container, prefix).tap do |collection_table|
         container.add_field reference_field_class.new(container, make_name("first", prefix), collection_table, true, false)
         container.add_field reference_field_class.new(container, make_name("last" , prefix), collection_table, true, false)

         collection_table.add_field reference_field_class.new(collection_table, make_name("next"    , prefix), collection_table, true, false)
         collection_table.add_field reference_field_class.new(collection_table, make_name("previous", prefix), collection_table, true, false)
      end
   end
   
   def lay_out_user_defined_type( type, container, prefix = nil )
      lay_out(type.base_type, container, prefix)
   end

   def lay_out_unknown_type( type, container, prefix = nil )
      container.top.describe
      fail
   end




   def scalar_field_type( sf_type )
      case sf_type
      when Schemaform::Schema::StringType
         if sf_type.typeof?(sf_type.schema.text_type) then
            text_field_type(sf_type.length)
         else
            ["blob", true]
         end
      when Schemaform::Schema::BooleanType
         boolean_field_type()
      when Schemaform::Schema::IntegerType
         integer_field_type(sf_type.range)
      when Schemaform::Schema::DateTimeType
         date_time_field_type()
      when Schemaform::Schema::EnumeratedType
         if sf_type.evaluated_type.is_a?(Schemaform::Schema::StringType) then
            text_field_type(sf_type.evaluated_type.length)
         else
            integer_field_type(sf_type.evaluated_type.range)
         end
      else
         fail sf_type.class.name
      end
   end
   
   def boolean_field_type()
      "integer"
   end
   
   def text_field_type( length = nil )
      [(length.exists? && length > 0 && length < 256) ? "varchar(#{length})" : "text", true]
   end
   
   def integer_field_type( range )
      "integer"
   end

   def date_time_field_type()
      ["datetime", true]
   end


   
   def make_name( name, prefix = nil )
      prefix ? prefix + separator + name.to_s : name.to_s
   end
   


protected
   def initialize( url )
      @url     = url
      @layouts = {}
      @monitor = Monitor.new()
   end





end # Adapter
end # Generic
end # Adapters
end # Schemaform
