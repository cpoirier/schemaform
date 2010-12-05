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
   # Defines a field within the entity.  If a block is given, the field is calculated,
   # and the type will be determined for you.  Otherwise, you must supply at least a type.
   
   def field( name, *data, &block )
      assert( !@fields.member?(name)               , "duplicate field name #{name}"                     )
      assert( @parent.nil? || !@parent.field?(name), "field name conflicts with field in parent entity" )
      
      field = nil
      if block_given? then
         field = Fields::DerivedField.new(name, &block)
      else
         type, additional = *data
         type_mapping = @schema.find_mapping( type )
         
         assert( type.exists?        , "please specify a type or a formula for this field" )
         assert( type_mapping.exists?, "unable to find mapping for type", {"type" => type} )

         field = Fields.StoredField.new(name, type_mapping, additional.fetch(:default, nil))
      end

      @fields[name] = field
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


require $schemaform.relative_path("field.rb")
