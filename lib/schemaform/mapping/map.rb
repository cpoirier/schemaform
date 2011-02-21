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

require Schemaform.locate("selector.rb")


#
# Describes how a Schema will be laid out for storage in the database.  Subclasses customize
# the Map for specific database systems.

module Schemaform
module Mapping
class Map
   include QualityAssurance
   extend QualityAssurance

   #
   # Builds a Map for the specified connection_url.
   
   def self.build( schema, connection_url, rebuild = false )
      @@maps         = {} unless defined?(@@maps)
      @@maps[schema] = {} unless @@maps.member?(schema)

      adapter_class = adapter_class_for( connection_url )
      if rebuild || !@@maps[schema].member?(adapter_class) then
         @@maps[schema][adapter_class] = adapter_class.new( schema, connection_url )
      end
      
      return @@maps[schema][adapter_class]
   end   
   

   #
   # Builds the Map with the specific schema.  Protected, as nobody should be building 
   # a base class Map directly.
   
   def initialize( schema, connection_url )
      @schema         = schema
      @connection_url = connection_url
      @tables         = []
      
      map_schema( schema )
   end


   #
   # Maps a "dotted" name (as a list of component names) into something the database can store.
   
   def map_name( *components )
      components.flatten.collect{|e| e.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase}.join("$")
   end
   

   #
   # Adds a Table to the Map.
   
   def add_table( table )
      @tables << table
   end


protected



   #
   # Maps a single Schema definition into the database.
   
   def map_schema( schema, base_name = Name.new(self) )
      schema_name = base_name.empty? ? Name.new(self) : base_name + schema.name
      
      schema.each_entity do |entity|
         map_entity( entity, schema_name )
      end
      
      schema.each_subschema do |subschema|
         map_schema( subschema, schema_name )
      end
      
      @tables.each do |table|
         puts table.to_sql
         puts ""
      end
   end
   

   #
   # Maps a single entity into tables and fields.
   
   def map_entity( entity, schema_name )
      table = Table.new( self, schema_name + entity.name, schema_name + entity.heading.name )

      #
      # Process top-level attributes in order.  However, we will defer anything that is
      # multi-valued, as we will require a subtable for that, and that requires the fully
      # mapped primary key.  Fortunately, multi-valued attributes can never be used in a 
      # primary key, so it isn't a problem.

      multivalued_attributes = []
      entity.each_attribute do |attribute|
         if attribute.resolve.multi_valued? then
            multivalued_attributes << attribute
         elsif entity.primary_key.member?(attribute) then
            map_attribute( attribute, table ) do |pass, specific, field|
               if pass == :pre then
                  check do 
                     attribute_type = specific.resolve
      
                     assert( specific.required?           , "entity primary keys can contain only required attributes"                        )
                     assert( attribute_type.single_valued?, "entity primary keys can contain only single-valued attributes"                   )
                     assert( key_worthy?(attribute_type)  , "[#{specific.full_name}] cannot be used in a primary key in [#{@connection_url}]" )
                  end
               elsif field then
                  table.primary_key.add( field )
               end
            end
         else
            map_attribute( attribute, table )
         end
      end
   
      #
      # Now, process any deferred attributes.
   
      multivalued_attributes.each do |attribute|
         map_attribute( attribute, table )
      end
   end
   
   
   #
   # Returns true if the specified type can be part of a key in the database.
   
   def key_worthy?( type )
      true
   end
   
   
   
   
   # ==========================================================================================
   #                                       Field Mapping
   # ==========================================================================================
   
   
   #
   # Maps a single attribute of any type, by dispatching to the attribute mapper for the 
   # specific type (scalar, tuple, set, relation).  You can pass a block if you need to 
   # perform additional processing on each (sub-)attribute.
   
   def map_attribute( attribute, table, base_name = Name.new(self), elide_name = false, &block ) 
      block.call( :pre, attribute, nil ) if block_given?     

      field = nil
      attribute_type = attribute.resolve
      if attribute_type.scalar_type? then
         field = map_scalar_attribute( attribute, table, base_name, elide_name, &block )
      else
         send( attribute_type.type_info.specialize("map", "attribute"), attribute, table, base_name, &block )
      end
      
      block.call( :post, attribute, field ) if block_given?
   end
   
   
   #
   # Maps a scalar attribute to a SQL field.  
   
   def map_scalar_attribute( attribute, table, base_name, elide_name, &block )
      field_name = elide_name ? base_name : base_name + attribute.name
      add_present_flag( table, field_name ) if attribute.optional?
      
      Field.new( table, field_name, map_scalar_type(attribute.resolve) )
   end


   #
   # Flattens a Tuple attribute into a table.

   def map_tuple_attribute( attribute, table, base_name, &block )
      if attribute.optional? then
         add_present_flag( table, base_name + attribute.name )
      end

      tuple = attribute.resolve
      tuple.each_attribute do |sub_attribute|
         map_attribute( sub_attribute, table, base_name + attribute.name, tuple.length == 1, &block ) 
      end
   end


   #
   # Flattens a Set attribute into a subtable.
   
   def map_set_attribute( attribute, table, base_name, &block )
      Table.new( self, table.name + base_name + attribute.name ).tap do |set_table|

         #
         # Copy of the primary key fields from the master table.
         
         owner_field_base_name = Name.new( self, "key_" + table.row_name.to_s )
         fields_to_copy = table.primary_key.fields         
         fields_to_copy.each do |field|
            Field.new( set_table, fields_to_copy.length == 1 ? owner_field_base_name : owner_field_base_name + field.name, field.type, field.allow_nulls? )
         end
         
         #
         # Sets are restricted to scalar and reference types.  Because the member type isn't
         # in an attribute, we'll have to process it directly.
           
         member_type = attribute.resolve.member_type.resolve
         if member_type.has_heading? then
            owned_field_base_name = Name.new( self, "referenced_" + member_type.context.context.heading.name )
            member_type.each_attribute do |sub_attribute|
               map_attribute( sub_attribute, set_table, owned_field_base_name, member_type.length == 1, &block )
            end
         else
            Field.new( set_table, Name.new(self, "member_value"), map_scalar_type(attribute.resolve) )
         end
      end
   end


   #
   # Flattens a Relation attribute into a subtable (or set thereof).
   
   def map_relation_attribute( attribute, table, base_name, &block )

   end
   
   
   def add_present_flag( table, name ) 
      Field.new( table, name + "" + "present", map_integer_type_for_range(0..1) )
   end
      


   
   # ==========================================================================================
   #                                       Type Mapping
   # ==========================================================================================
   
   def map_scalar_type( scalar_type )
      storage_type   = scalar_type.storage_type
      handler_method = storage_type.specialize_method_name( "map" )
      if responds_to?(handler_method) then
         send( handler_method, scalar_type )
      else
         fail "unrecognized storage type class [#{storage_type.class.name}]"
      end
   end
   
   
   def map_text_type( type )
      length = nil
      type.each_constraint do |constraint|
         if constraint.is_a?(Definitions::TypeConstraints::LengthConstraint) then
            length = [length, constraint.length].compact.min 
         end
      end
      
      map_text_type_for_length( length )
   end
   
   def map_text_type_for_length( length = nil )
      length && length < 256 ? "varchar(#{length})" : "text"
   end
   
      
   def map_binary_type( type )
      "binary"
   end
   
   def map_numeric_type( type )
      fail
   end
   
   def map_integer_type( type )
      lower_limit = nil
      upper_limit = nil
      
      type.each_constraint do |constraint|
         if constraint.is_a?(Definitions::TypeConstraints::RangeConstraint) then
            lower_limit = [lower_limit, range.min].compact.max
            upper_limit = [upper_limit, range.max].compact.min
         end
      end

      map_integer_type_for_range( (lower_limit.nil? || lower_limit > upper_limit) ? nil : lower_limit..upper_limit )
   end
   
   def map_integer_type_for_range( range = nil )
      return "integer" if range.nil?
      
      {            0..65535      => "unsigned smallint",
              -32768..32767      => "smallint",
                   0..4294967295 => "unsigned integer",
         -2147483648..2147483647 => "integer"
      }.each do |set, name|
         return name if range.min >= set.min && range.max <= range.max 
      end
      
      fail "unable to map an integer type for range #{range.to_s}"
   end


   def map_date_time_type( type )
      "datetime"
   end



protected


   # ==========================================================================================
   #                                       Adapter Management
   # ==========================================================================================

   #
   # Retrieves the Map class for the specified connection URL.

   def self.adapter_class_for( connection_url, fail_if_missing = true )
      @@selectors = [] unless defined?(@@selectors) && @@selectors.is_an?(Array)
      @@selectors.each do |selector|
         return selector.adapter_class if selector.matches?(connection_url)
      end
   
      fail( "unable to find mapper for #{connection_url}" ) if fail_if_missing
      return nil
   end


   #
   # Registers a Map class.  You can pass a pattern or a block which will be
   # used to determine applicability to the current URL string.

   def self.register_adapter_class( adapter_class, url_pattern = nil, &url_tester )
      @@selectors = [] unless defined?(@@selectors) && @@selectors.is_an?(Array)
      if url_pattern.nil? then
         assert( block_given?, "expected either a pattern or a block" )
         @@selectors << BlockBasedSelector.new( adapter_class, &url_tester )
      else
         @@selectors << PatternBasedSelector.new( adapter_class, url_pattern )
      end
   end

      
end # Map
end # Mapping
end # Schemaform


Dir[Schemaform.locate("adapters/*.rb")].each do |path| 
   require path
end
