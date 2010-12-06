#!/usr/bin/env ruby -KU
# =============================================================================================
# SchemaForm
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
# A single entity within the schema.

module SchemaForm
module Model
class Entity
      
   def initialize( schema, name, parent = nil, &block )
      @schema = schema
      @name   = name
      @parent = parent
      @fields = {}
      @keys   = {}
      instance_eval(&block) if block_given?
   end
   
   
   #
   # Returns true if the named field is defined in this or any parent entity.
   
   def field?( name, check_parent = true )
      return true if @fields.member?(name)
      return @parent.field?(name) if check_parent && @parent.exists?
      return false
   end
   
   #
   # Returns true if the named key is defined in this or any parent entity.
   
   def key?( name, check_parent = true )
      return true if @keys.member?(name)
      return @parent.key?(name) if check_parent && @parent.exists?
      return false
   end
   
   
   #
   # Defines a field within the entity.  If a block is given, the field is calculated,
   # and the type will be determined for you.  Otherwise, you must supply at least a type.
   
   def field( name, *data, &block )
      assert( !@fields.member?(name)               , "duplicate field name #{name}"                     )
      assert( @parent.nil? || !@parent.field?(name), "field name conflicts with field in parent entity" )
      
      field = nil
      block = data.shift if data.first.is_a?(Proc) 
      if block.exists? then
         field = Fields::DerivedField.new(self, name, block)
      else
         type, additional = *data
         type_mapping = @schema.find_mapping( type )
         
         assert( type.exists?        , "please specify a type or a formula for this field" )
         assert( type_mapping.exists?, "unable to find mapping for type", {"type" => type} )

         field = Fields::StoredField.new(self, name, type_mapping, additional.exists? ? additional.fetch(:default, nil) : nil)
      end

      @fields[name] = field
   end

   
   #
   # Defines a candidate key on the entity -- a subset of fields that can uniquely identify
   # a record within the set.  You can name the key by passing a one-entry hash instead of
   # an array of field name.  If you supply no keys, the full set of stored fields is used
   # as the key.  Note: [:x, :y] is the same key as [:y, :x].  The system will not stop
   # you from making both, but there is likely no benefit to you for doing so.
   #
   # Examples:
   #   key :field_name
   #   key :field_name, :other_field_name
   #   key :key_name => :field_name
   #   key :key_name => [:field_name]
   #   key :key_name => [:field_name, :other_field_name]
   
   def key( *names )
      key_name = nil
      if names[0].is_a?(Hash) then
         key_name = names[0].keys.first
         names = names[0][key_name].as_array
      end
      
      key_name = names.collect{|name| name.to_s}.join("_and_") if key_name.nil?
      
      assert( !key?(key_name), "key name #{key_name} already exists in entity #{@name}" )
      names.each do |name|
         assert( field?(name), "key field #{name} is not a member of entity #{@name}" )
      end
            
      @keys[key_name] = Key.new( self, key_name, names )
   end

protected

   def method_missing( symbol, *args )
      if symbol.to_s.slice(-5..-1) == "_type" then
         @schema.send( symbol, *args )
      else
         super
      end
   end

   
end # Entity
end # Model
end # SchemaForm


require $schemaform.local_path("field.rb")
require $schemaform.local_path("key.rb")
