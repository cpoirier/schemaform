#!/usr/bin/env ruby -KU
# =============================================================================================
# SchemaForm
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Contact]   Chris Poirier (cpoirier at gmail dt com)
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

require 'monitor'


#
# Provides a naming context and a unit of storage within the SchemaForm system.  Multiple
# Schemas can coexist within one physical database, but names are unique.

module SchemaForm
module Model
class Schema
   
   #
   # Defines a schema and calls your block to fill it in.  With this method, your
   # block can treat the Schema interface as a DSL.
   
   def self.define( name, &block )
      @@monitor.synchronize do
         if @@schemas.member?(name) then
            raise AssertionFailure.new("duplicate schema name", {"name" => name, "existing" => @@schemas[name].source})
         end
         
         @@schemas[name] = self.new( name, caller()[0], &block )
      end
   end
   
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
      
   #
   # Defines an entity within the Schema.
   
   def define( name, parent = nil, &block )
      assert( !@entities.member?(name), "duplicate entity name", {"name" => name} )
      assert( parent.nil? || @entities.member?(parent), "parent not defined", {"name" => parent} )
      @entities[name] = Entity.new( self, name, parent.nil? ? nil : @entities[parent], &block )      
   end
   
   
   #
   # Defines a mapping from Ruby to SchemaForm types, and how to convert from one to 
   # the other.  When defining fields, you may use either expression, and the mappings
   # will be used to determine the other type.  All parameters are supplied as pairs.  
   # The only required one is from Ruby class to SchemaForm type.  You can additionally
   # override the default conversion routines by providing :write (Ruby => SchemaForm)
   # and :read (SchemaForm => Ruby) procs.
   #
   # Example (assumes hypothetical Ruby SHA1 class):
   #   map SHA1 => text(40), :write => :to_s, :read => lambda {|v| SHA1.new(v)}
   #   map SHA1 => text(40), :write => :to_s, :read => lambda {|v| SHA1.new(v)}
      
   def map( data )
      ruby_type = sf_type = writer = reader = nil
      data.each do |key, value|
         case key
         when :read
            reader = value
         when :write
            writer = value
         else
            assert( key.is_a?(Class) , "please map from Ruby class"      ) 
            assert( value.is_a?(Type), "please map to a SchemaForm Type" )
            ruby_type = key
            sf_type   = value
         end
      end
      
      mapping = TypeMapping.new( ruby_type, schemaform_type, writer, reader )
      
      @mappings_by_ruby_type = [] unless @mappings_by_ruby_type.member?(ruby_type)
      @mappings_by_sf_type   = [] unless @mappings_by_sf_type.member?(sf_type)
      
      assert( !@mappings_by_ruby_types[ruby_type].member?(sf_type), "type mapping from Ruby type #{ruby_type} to Schema type #{schema_type} already defined" )
      assert( !@mappngs_by_sf_type[sf_type].member?(ruby_type)    , "type mapping from Schema type #{schema_type} to Ruby type #{ruby_type} already defined" )

      @mappings_by_ruby_type[ruby_type][sf_type] = mapping
      @mappings_by_sf_type[sf_type][ruby_type]   = mapping
   end

   
   def text_type( character_limit = INFINITY )
      TextType.new(character_limit)
   end
   
   def binary_type( byte_limit = INFINITY )
      BinaryType.new(byte_limit)
   end
   
   def integer_type( byte_width = 4 )
      IntegerType.new(byte_width)
   end
   
   def real_type( byte_width = 8 )
      RealType.new(byte_width)
   end
   
   def boolean_type()
      BooleanType.new()
   end
   
   def datetime_type()
      DatetimeType.new()
   end


   
   
   
   #
   # Returns a relation representing the entirety of a class.
   
   def from( class_name )
   end
   
   def all( class_name )
      return from( class_name )
   end
   

   
   
   
   
   #
   # Returns the schema name.
   
   attr_reader :name
   
   #
   # Returns the source file and line of the Schema, for use in error reports.
   
   attr_reader :source
   
   #
   # Returns the TypeMapping for the specified Ruby or SchemaForm type.
   
   def find_mapping( type )
      if type.is_a?(SchemaForm::Types::Type) then
         type.type_closure.reverse.each do |type|   # When mapping from a named SF type to a Ruby type, we want the most general mapping!
            return @schema_types[type].first if @schema_types.member?(type)
         end
      else
         while type
            return @ruby_types[type].first if @ruby_types.member?(type)
            type = type.superclass
         end
      end
      
      return nil
   end

   


private
   
   @@monitor = Monitor.new()
   @@schemas = {}
   
   def initialize( name, source, &block )
      @name                  = name
      @source                = source
      @entities              = {}
      @mappings_by_ruby_type = {}
      @mappings_by_sf_type   = {}
      
      register_native_types()

      instance_eval(&block) if block_given?
   end
   
   
   def register_type( type )
      assert( !@all_types.member?(type.name), "duplicate type name #{type.name}" )
      
      @all_types[type.name]    = type
      @scalar_types[type.name] = type unless type.is_an?(InternalType)
   end
   
      
   def register_native_types()      
      
      # all_type  = register_type( InternalType.new(self, "all" , nil     ) )
      # void_type = register_type( InternalType.new(self, "void", all_type) )
      # fail_type = register_type( InternalType.new(self, "fail", all_type) )
      # any_type  = register_type( InternalType.new(self, "any" , all_type) )
      # 
      # @root_type = all_type
      # @any_type  = any_type
      # 
      # #
      # # Intermediate, non-storable types.
      # 
      # number_type    = register_type( InternalType.new(self, "number", any_type) )
      # object_type    = register_type( InternalType.new(self, "object", any_type) )
      # 
      # @object_type = object_type
      # 
      # opaque_type    = register_type( InternalType.new(self, "opaque"   , any_type   ) )
      # recordset_type = register_type( InternalType.new(self, "recordset", opaque_type) )   # SQL recordset object
      # command_type   = register_type( InternalType.new(self, "command"  , opaque_type) )   # SQL command object
      # node_type      = register_type( InternalType.new(self, "node"     , opaque_type) )   # XML node
      # 
      # #
      # # Basic storable types.
      # 
      # integer_type    = register_type( InternalType.new(self, "integer",   number_type , true, 0) )
      # boolean_type    = register_type( InternalType.new(self, "boolean",   integer_type, true, 0) )
      # id_type         = register_type( InternalType.new(self, "id",        integer_type, true, 0) )
      # datetime_type   = register_type( InternalType.new(self, "datetime",  any_type    , true, P("now")  ) )
      #                 
      # binary_type     = register_type( UndimensionedStringType.new(self, "binary", any_type   , true, "") )
      # text_type       = register_type( UndimensionedStringType.new(self, "text"  , binary_type, true, "") )
      # identifier_type = register_type( InternalType.new(self, "identifier", text_type.dimension(30), true, "") )
      # 
      # @boolean_type   = boolean_type
      # @false_type     = register_type( InternalType.new(self, "false", boolean_type, true) )
      # @true_type      = register_type( InternalType.new(self, "true" , boolean_type, true, Scanner::Token.atom("1")) )
      # 
      # #
      # # Basic parameterized types.
      # 
      # list_type      = tm.register_type(  GenericType.new(tm, "list"    , any_type     ) )
      # relation_type  = tm.register_type( InternalType.new(tm, "relation", any_type     ) )
      # class_type     = tm.register_type( InternalType.new(tm, "class"   , relation_type) )
      # 
      # tm.relation_type = relation_type
      # 
      # 
      # # @arglist_type  = register_type( ListType.new(self, "arglist", @list_type, @any_type)          )
      # 
      # #
      # # Configure the Token system for simplified type resolution.
      # 
      # $debug.warn( "removed Token.missing.datatype set -- is it being used?" ) if $debug
      # # Token.missing.datatype = void_type
   end
   
   
end # Schema
end # Model
end # SchemaForm


require $schemaform.relative_path("entity.rb"      )
require $schemaform.relative_path("type_mapping.rb")
