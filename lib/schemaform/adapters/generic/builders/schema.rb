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
# Adds schema building code to the Adapter.

module Schemaform
module Adapters
module Generic
class Adapter
   
   module AttributeAspects
      Value                    = Language::Productions::ValueAccessor
      Present                  = Language::Productions::PresentCheck
      # ListFirstMember          = Language::Productions::
      # ListLastMember           = Language::Productions::
      # ListMemberNextMember     = Language::Productions::
      # ListMemberPreviousMember = Language::Productions::
   end
   
   
   #
   # Lays out a Schema for use with the database. 
   
   def lay_out( definition )
      @monitor.synchronize do
         unless @schema_maps.member?(definition)
            schema_name = Name.build(*definition.path)
            @schema_maps[definition] = SchemaMap.new(definition).tap do |schema_map|

               #
               # Create anchor tables and entity maps for each entity first. We need them in place for reference resolution.

               definition.entities.each do |entity|
                  schema_map.map(entity, define_table(schema_name + entity.name)) do |entity_map, table|
                     if entity.has_base_entity? then
                        table.identifier = table.define_reference_field(entity.id, entity_map.base_map.anchor_table, build_primary_key_mark())
                        entity_map.link_child_to_parent(table.identifier)
                     else
                        table.identifier = table.define_identifier_field(entity.id, build_primary_key_mark())
                     end
                  end
               end

               #
               # Now, fill them in with the basic data structure.

               definition.entities.each do |entity|
                  builder = @overrides.fetch(:lay_out_builder_class, LayOutBuilder).new(self, schema_map.entity_maps[entity])

                  entity.heading.attributes.each do |attribute|
                     next if attribute.name == entity.id
                     next if entity.base_entity && entity.base_entity.declared_heading.attribute?(attribute.name)

                     dispatch_lay_out(attribute, builder)
                  end
               end
            end
         end
      end
      
      @schema_maps[definition]
   end


   def dispatch_lay_out( element, builder )
      send_specialized(:lay_out, element, builder)
   end
   
   def lay_out_attribute( attribute, builder )
      builder.with_attribute(attribute) do
         send_specialized(:lay_out, attribute.type, builder)
         yield if block_given?
      end
   end
   
   def lay_out_optional_attribute( attribute, builder )
      lay_out_attribute(attribute, builder) do
         builder.define_meta(AttributeAspects::Present, "present", type_manager.boolean_type, build_required_mark())
      end
   end
   
   def lay_out_volatile_attribute( attribute, builder )
      warn_todo("what do we do about mapping volatile attributes?")
   end
   
   
   
   def lay_out_tuple( tuple, builder )
      tuple.attributes.each do |attribute|
         dispatch_lay_out(attribute, builder)
      end
   end
   
   
   def lay_out_type( type, builder )
      fail "no lay_out support for #{type.class.name}"
   end

   def lay_out_reference_type( type, builder )
      warn_todo("reference field null/default handling")
      
      referenced_entity_map = builder[type.referenced_entity] or fail "couldn't resolve a reference to entity [#{type.entity_name}]"
      builder.define_scalar(type_manager.identifier_type, build_reference_mark(referenced_entity_map.anchor_table, true))
   end

   def lay_out_identifier_type( type, builder )
      lay_out_reference_type(type, builder)
   end

   def lay_out_scalar_type( type, builder )
      builder.define_scalar(type_manager.scalar_type(type))
   end

   def lay_out_tuple_type( type, builder )
      dispatch_lay_out(type.tuple, builder)
   end
   
   def lay_out_user_defined_type( type, builder )
      dispatch_lay_out(type.base_type, builder)
   end

   def lay_out_unknown_type( type, builder )
      fail
   end
   

   def lay_out_collection_type( type, builder )
      builder.define_child_table(true, "record") do
         yield if block_given?
      end
   end
   
   def lay_out_collection_type__member_type( member_type, builder )
      if member_type.naming_type? then
         dispatch_lay_out(member_type, builder)
      else
         builder.with_name("value") do
            dispatch_lay_out(member_type, builder)
         end
      end
   end
   
   def lay_out_set_type( type, builder )
      lay_out_collection_type(type, builder) do
         lay_out_collection_type__member_type(type.member_type, builder)
      end
   end
   
   def lay_out_list_type( type, builder )      
      field_type       = type_manager.identifier_type
      member_reference = nil

      lay_out_collection_type(type, builder) do
         member_reference = build_reference_mark(builder.current_table)
         lay_out_collection_type__member_type(type.member_type, builder)

         warn_once("list meta fields cannot be completed until Productions exist for accessing them")
         # builder.define_meta(AttributeAspects::ListMemberNextMember, "next"    , field_type, member_reference)
         # builder.define_meta(AttributeAspects::ListMemberPreviousMember, "previous", field_type, member_reference)
      end

      warn_once("list meta fields cannot be completed until Productions exist for accessing them")
      # builder.define_meta(AttributeAspects::ListFirstMember, "first", field_type, member_reference)
      # builder.define_meta(AttributeAspects::ListLastMember , "last" , field_type, member_reference)
   end





   #
   # Lay out builder used by the lay_out*() routines to ensure both Tables and EntityMaps are built in 
   # step. If you need to change this, be sure to pass the class as :lay_out_builder_class in the Adapter 
   # overrides.
   
   class LayOutBuilder
      include QualityAssurance
      TableFrame     = Struct.new(:table, :default_name, :name_stack)
      AttributeFrame = Struct.new(:attribute, :aspect)
      
      
      def initialize( adapter, entity_map )
         @adapter         = adapter
         @entity_map      = entity_map
         @schema_map      = entity_map.schema_map
         @table_stack     = [TableFrame.new(entity_map.anchor_table, @adapter.build_name(), [])]
         @attribute_stack = []
      end
      
      def []( entity )
         @schema_map[entity]
      end
      
      def current_table()
         @table_stack.top.table
      end
      
      def with_attribute( attribute )
         @attribute_stack.push_and_pop(AttributeFrame.new(attribute, AttributeAspects::Value)) do
            name_stack.push_and_pop((name_stack.top || @adapter.build_name()) + attribute.name) do
               yield
            end
         end
      end
      
      def with_meta( aspect, name )
         @attribute_stack.push_and_pop(AttributeFrame.new(@attribute_stack.top.attribute, :purpose)) do
            name_stack.push_and_pop((name_stack.top || @table_stack.top.default_name) + name) do
               yield
            end
         end
      end
      
      def with_name( name )
         name_stack.push_and_pop((name_stack.top || @table_stack.top.default_name) + name) do
            yield
         end
      end

      def define_scalar( type_info, *field_marks )
         @table_stack.top.table.define_field(name_stack.top, type_info, *field_marks).tap do |field|
            frame = @attribute_stack.top
            @entity_map.link_field_to_attribute(field, frame.attribute, frame.aspect)
         end
      end
      
      def define_meta( purpose, name, type_info, *field_marks )
         with_meta(purpose, name) do
            define_scalar(type_info, *field_marks)
         end
      end
      
      def define_child_table( has_many, default_name = "record" )
         parent_table = @table_stack.top.table
         default_name = @adapter.build_name(default_name)
         
         @adapter.define_table(parent_table.name + name_stack.top) do |table|
            owner_field = table.define_reference_field(default_name + "owner", parent_table)
            @entity_map.link_child_to_parent(owner_field)

            if parent_table != @entity_map.anchor_table then
               context_field = table.define_reference_field(default_name + "context", @entity_map.anchor_table)
               @entity_map.link_child_to_context(context_field)
            end
            
            if has_many then
               table.identifier = table.define_identifier_field(default_name + "id", @adapter.build_primary_key_mark())
            else
               table.identifier = owner_field
               owner_field.marks << @adapter.build_primary_key_mark()
            end
            
            @table_stack.push_and_pop(TableFrame.new(table, default_name, [])) do
               yield
            end
         end
      end
      
   protected
      def name_stack()
         @table_stack.top.name_stack
      end
      
   end



end # Adapter
end # Generic
end # Adapters
end # Schemaform
