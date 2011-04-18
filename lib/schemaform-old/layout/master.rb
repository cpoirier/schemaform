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
# The anchor for the layout of a Schema definition into a working system.

module Schemaform
module Layout
class Master < Layout
   
   def self.build( name )
      Builder.new(name).tap{|builder| yield(builder)}.master
   end

   attr_reader :name, :sql_schema, :schema_class
   
   def initialize( name )
      @name           = name
      @sql_schema     = SQL::Schema.new( @name )
      @schema_class   = Ruby::SchemaClass.define_subclass( @name )
      @tuple_classes  = {}
      @entity_classes = {}
   end   


   def entity_class_for( name )
      unless @entity_classes.member?(name)
         @entity_classes[name] = Ruby::EntityClass.define( name, @schema_class )
      end
      
      @entity_classes[name]
   end
   
   
   def tuple_class_for( name )
      unless @tuple_classes.member?(name)
         @tuple_classes[name] = Ruby::TupleClass.define( name, @schema_class )
      end
      
      @tuple_classes[name]
   end


end # Master
end # Layout
end # Schemaform


Dir[Schemaform.locate("sql/*.rb" )] {|path| require path}
Dir[Schemaform.locate("ruby/*.rb")] {|path| require path}
