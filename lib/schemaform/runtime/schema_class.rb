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


require "rubygems"
require "sequel"
require Schemaform.locate("entity_class.rb")
require Schemaform.locate("tuple_class.rb" )


#
# Provides the database-backed Schema functionality at runtime.

module Schemaform
module Runtime
class SchemaClass
   extend Sequel::Inflections
   
   #
   # Instantiate the SchemaClass, linking it to an actual database, possibly with a table name prefix.
 
   def initialize( database, prefix = nil )
      @database = database
      @map      = Mapping::Map.build( self.class.definition, @database.connection_string ).prefix( prefix )
      @entities = {}
   end
   
   
   #
   # Builds a top-level class for the supplied Definitions::Schema.
   
   def self.build( definition )
      schema_class = Class.new(self) do
         @@definition = definition
         def self.definition()
            @@definition
         end
         
         #
         # Define a TupleClass for every tuple type in the Schema.
         
         definition.each_tuple_type do |tuple_type|
            tuple_class = Class.new(TupleClass) do
               @@definition = tuple_type
               def self.definition()
                  @@definition
               end
            end
            
            const_set( camelize(tuple_type.name.to_s), tuple_class )
         end
         
         #
         # Define an EntityClass and an accessor for every entity in the Schema.

         definition.each_entity do |entity|
            entity_class = Class.new(EntityClass) do
               @@definition = entity
               def self.definition()
                  @@definition
               end
            end
            
            const_set( camelize(entity.name.to_s), entity_class )
         end
      end
      
      #
      # Define the Schema class as a top-level name, so it can be easily accessed and extended.
      
      Object.const_set( definition.name, schema_class )
   end
   
   

end # SchemaClass
end # Runtime
end # Schemaform