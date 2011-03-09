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


#
# A helper class for building the Layout.

module Schemaform
module Layout
class Builder
   
   attr_reader :master
   
   def initialize( name )
      @master       = Master.new( name )
      @entity_class = nil
      @tuple_class  = nil
      @table        = nil
      @field_prefix = dot_name()
      @key          = nil
   end

   #
   # Makes a DottedName from the supplied components.  Used for table and field naming.
   
   def dot_name( *components )
      SQL::DottedName.build( *components )
   end
   

   #
   # Defines a new EntityClass and makes it the current target for your operations.
   
   def in_entity_class( name, &block )
      with_value( :entity_class, @master.entity_class_for(name), &block )
   end
   
   
   #
   # Defines a new TupleClass and makes it the current target for your operations.
   
   def in_tuple_class( name, &block )
      with_value( :tuple_class, @master.tuple_class_for(name), &block )
   end
   
   
   #
   # Defines a new Table and makes it the current target for your operations.  Assumes that
   # tables defined within the scope of another table are subtables, and primary key elements 
   # are automatically copied "down".
   
   def define_table( name, &block )
      table = if @table then
         warn_once( "TODO: copy over primary key information to subtable" )
         SQL::Table.new( @master, @table.name + @field_prefix + name )
      else
         SQL::Table.new( @master, dot_name(name) )
      end

      with_values( :table => table, :field_prefix => dot_name(), :key = nil, &block )
   end

   
   #
   # Defines a new naming scope for your operations.  The naming scope affects primarily table
   # fields.

   def with_name( name, &block )
      with_variable( :field_prefix, @field_prefix + name, &block )
   end


   #
   # Creates a primary key scope.  All fields created during its duration will be added to the
   # primary key for the current table.
   
   def in_primary_key( &block )
      with_variable( :key, @table.primary_key, &block )
   end


   #
   # Defines a field in the current table.
   
   def define_field( name, type, allow_nulls = false )
      @table.define_field( @field_prefix + name, type, allow_nulls )
      @key.add_field( @field_prefix + name ) if @key
   end
   
   
   #
   # Defines a reader for a tuple.  Pass a block if you need a custom preamble.
   
   def define_tuple_reader( name, type, &preamble )
   end
   
   
   #
   # Defines a writer for a tuple.  Pass a block if you need a custom preamble.
   
   def define_tuple_writer( name, type, &preamble )
   end
   
   
   #
   # Defines a default value for a writable tuple attribute.  Value can alternatively
   # be a block.
   
   def define_attribute_default( name, value )
      tuple_class.define_attribute_default( name, value )
   end
   
   
   

end # Builder
end # Layout
end # Schemaform