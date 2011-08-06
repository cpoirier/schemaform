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
                        table.identifier = table.define_field(entity.id, type_manager.identifier_type, reference_mark(entity_map.base_map.anchor_table), primary_key_mark())
                        entity_map.link_child_to_parent(table.identifier)
                     else
                        table.identifier = table.define_field(entity.id, type_manager.identifier_type, generated_mark(), primary_key_mark())
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
      
      @schemas[definition]
   end


   def dispatch_lay_out( element, builder )
      send_specialized(:lay_out, element, builder)
   end
   
   def lay_out_attribute( attribute, builder )
      builder.with_attribute(attribute) do
         send_specialize(:lay_out, element, builder))
         yield if block_given?
      end
   end
   
   def lay_out_optional_attribute( attribute, builder )
      lay_out_attribute(attribute, builder) do
         builder.define_meta(:present, type_manager.boolean_type, required_mark())
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
      builder.define_scalar(type_manager.identifier_type, reference_mark(referenced_entity_map.anchor_table, true))
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
      builder.define_child_table("record") do
         yield if block_given?
      end
   end
   
   def lay_out_collection_type__member_type( member_type, builder )
      if member_type.naming_type? then
         dispatch_lay_out(member_type, builder)
      else
         builder.with_meta("value") do
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
         member_reference = reference_mark(builder.current_table)
         lay_out_collection_type__member_type(type.member_type, builder)

         builder.define_meta("next"    , field_type, member_reference)
         builder.define_meta("previous", field_type, member_reference)
      end

      builder.define_meta("first", field_type, member_reference)
      builder.define_meta("last" , field_type, member_reference)
   end





   #
   # Lay out builder used by the lay_out*() routines to ensure both Tables and EntityMaps are built in 
   # step. If you need to change this, be sure to pass the class as :lay_out_builder_class in the Adapter 
   # overrides.
   
   class LayOutBuilder
      def initialize( adapter, entity_map )
         @adapter    = adapter
         @entity_map = entity_map
      end
      
      
      
   end



   # 
   # def self.build_master_table( schema, name, id_name = nil, base_table = nil )
   #    name = Name.build(name)
   #    schema.adapter.table_class.new(schema, name).tap do |table|
   #       modifier = base_table ? ReferenceMark.build(base_table) : GeneratedMark.build()
   #       table.identifier = table.define_field(id_name || Name.build("id", name.last), schema.adapter.type_manager.identifier_type, modifier, PrimaryKeyMark.build())
   #    end
   # end
   # 
   # def self.build_child_table( schema, parent_table, name, has_many = true )
   #    schema.adapter.table_class.new(schema, parent_table.name + name).tap do |table|
   #       table.owner = table.define_field(Name.build("owner", parent_table.identifier.name), schema.adapter.type_manager.identifier_type, ReferenceMark.build(parent_table))
   # 
   #       if has_many then
   #          table.identifier = table.define_field(Name.build("table", "id"), schema.adapter.type_manager.identifier_type, GeneratedMark.build(), PrimaryKeyMark.build())
   #       else
   #          table.owner.marks << PrimaryKeyMark.build()
   #          table.identifier = table.owner
   #       end
   #    end
   # end
   # def define_master_table( name, id_name = nil, base_table = nil )
   #    register @adapter.table_class.build_master_table(self, name, id_name, base_table)
   # end
   # 
   # def define_child_table( parent_table, name )
   #    register @adapter.table_class.build_child_table(self, parent_table, name)
   # end
   # 
   # def build_entity_map( entity )
   #    
   # end
   # 
   
   

end # Adapter
end # Generic
end # Adapters
end # Schemaform
