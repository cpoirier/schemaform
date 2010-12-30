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
# A single entity within the schema.

module Schemaform
module Model
class Entity
   include Quality
      
   def initialize( schema, name, parent = nil, &block )
      @schema      = schema
      @name        = name
      @parent      = parent
      @fields      = {}
      @keys        = {}
      @enumeration = nil
      @dsl         = DefinitionLanguage.new( self )
      
      @dsl.instance_eval(&block) if block_given?
   end
   
   attr_reader :schema, :name, :parent, :fields, :keys
   attr_accessor :enumeration
   
   
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
   # If true, this entity is enumerated.
   
   def enumerated?()
      @enumeration.exists?
   end
   

   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   
   class DefinitionLanguage
      include Quality
      
      def initialize( entity )
         @entity = entity
      end
      
   
      #
      # Defines a required field or subtuple within the entity.  To define a subtuple, supply a 
      # block instead of a type.
   
      def required( name, *data )
         modifiers = data.last.is_a?(Hash) ? data.pop : {}
         modifiers[:optional] = false
      
         if block_given? then
            assert( data.empty?, "specify either a type or a block, not both" )
            warn_nyi( "subtuple support" )
         else
            base_type = data.shift
            type_check( base_type, [Class, Symbol] )
            assert( data.empty?, "expected type and modifiers" )
            @entity << Fields::StoredField.new(self, name, [base_type, modifiers])
         end
      end
   
   
      #
      # Defines an optional field or subtuple within the entity.  To define a subtuple, supply a 
      # block instead of a type.
   
      def optional( name, *data )
         modifiers = data.last.is_a?(Hash) ? data.pop : {}
         modifiers[:optional] = true
      
         if block_given? then
            assert( data.empty?, "specify either a type or a block, not both" )
            warn_nyi( "subtuple support" )
         else
            base_type = data.shift
            type_check( base_type, [Class, Symbol] )
            assert( data.empty?, "expected type and modifiers" )
            @entity << Fields::StoredField.new(self, name, [base_type, modifiers])
         end
      end


      #
      # Defines a derived field within the entity.  Supply a Proc or a block.  
   
      def derived( name, proc = nil, &block )
         assert( proc.nil? ^ block.nil?, "expected a Proc or block" )
         field = Fields::DerivedField.new(self, name, proc.nil? ? block : proc)
         @entity << field
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
      
         assert( !@entity.key?(key_name), "key name #{key_name} already exists in entity #{@name}" )
         names.each do |name|
            assert( @entity.field?(name), "key field #{name} is not a member of entity #{@name}" )
         end
            
         @entity.keys[key_name] = Key.new( self, key_name, names )
      end
   
   
      #
      # Enumerates named values within a code table.  Most entities won't need this, but for
      # those few that do, it makes a lot of things more convenient.  The enumeration code
      # will automatically create the necessary fields in an empty entity, or can use any
      # pair of appropriately typed fields (specified with enumerate_into).  
      #
      # Examples:
      #   entity :Codes do
      #     enumerate :first, :second, :fourth, 4, :fifth
      #   end
      #
      #   entity :Codes do
      #     field :a_name , identifier_type()
      #     field :a_value, integer_type()   
      #     
      #     enumerate :first, :second, :fourth, 4, :fifth
      #   end
      #
      #   entity :Codes do
      #     field :a_name , identifier_type()
      #     field :a_value, integer_type()   
      #     field :public , boolean_type()
      #
      #     enumerate do
      #       define :first , 1, true
      #       define :second, 2, false
      #     end
      #   end

      def enumerate( *data, &block )
         assert( @entity.parent.nil?     , "enumerated entities cannot have a parent" )
         assert( @entity.enumeration.nil?, "entity is already enumerated"             )
      
         if @entity.fields.empty? then
            required :name , :identifier
            required :value, :integer
         else
            assert( @entity.fields.length >= 2, "an enumerated entity needs at least name and value fields" )
            # TODO type check the first two fields, once you figure out how best to do it
         end
      
         @entity.enumeration = Enumeration.new( self )
            
         if block then
            @entity.enumeration.fill(block)
         else
            assert( @entity.fields.count == 2, "to use the simple enumeration form, the entity must have only two fields" )

            @entity.enumeration.fill do
               value = 1
               until data.empty?
                  name  = data.shift
                  value = data.shift if data.first.is_an?(Integer)
               
                  assert( name.is_a?(Symbol), "expected a symbol or value, found #{name.class.name}" )
               
                  define name, value
                  value += 1
               end
            end
         end
      end
   end
   
   


   def <<( field )
      name = field.name
      
      assert( name.is_a?(Symbol)                   , "please use only Ruby symbols for field names"     )
      assert( !@fields.member?(name)               , "duplicate field name #{name}"                     )
      assert( @parent.nil? || !@parent.field?(name), "field name conflicts with field in parent entity" )
      
      @fields[name] = field
      self
   end
   
   
end # Entity
end # Model
end # Schemaform


require Schemaform.locate("field.rb")
require Schemaform.locate("key.rb")
require Schemaform.locate("enumeration.rb")
