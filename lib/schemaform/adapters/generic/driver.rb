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
# Walks a Schema to lay out structures in tables and fields.

module Schemaform
module Adapters
module Generic
class Driver
   extend QualityAssurance
   
   def self.lay_out( element, container, prefix = nil )
      current_class = element.class
      while current_class
         specialized = current_class.specialize_method_name("lay_out")
         return self.send(specialized, element, container, prefix) if self.responds_to?(specialized)
         current_class = current_class.superclass
      end
      fail "unsupported element class #{element.class.name}"
   end
      
   def self.lay_out_schema( schema )
      Schema.new(schema).tap do |layout|
         names = {}

         #
         # Create the master tables first. We need them in place for references.

         schema.entities.each do |entity|
            names[entity.name] = entity.name.to_s.identifier_case
            layout.define_table(names[entity.name], entity.id)
         end
         
         #
         # Now, fill them in.

         schema.entities.each do |entity|
            master_table = layout.schema.tables[names[entity.name]]
            entity.heading.attributes.each do |attribute|
               next if attribute.name == entity.id
               next if entity.base_entity && entity.base_entity.declared_heading.member?(attribute.name)

               lay_out(attribute, master_table)
            end
         end
      end
   end
   
   def self.lay_out_element( element, container, prefix = nil )
      fail "there should be a lay_out entry-point for #{element.class.name}"
   end
   
   def self.lay_out_entity( entity, container, prefix = nil )
      fail "this should have been handled in lay_out_schema"
   end

   def self.lay_out_tuple( tuple, container, prefix = nil )
      tuple.attributes.each do |attribute|
         lay_out(attribute, container, prefix)
      end      
   end
   
   def self.lay_out_attribute( attribute, container, prefix = nil )
      lay_out(attribute.type, container, make_name(attribute.name, prefix))
   end
   
   def self.lay_out_optional_attribute( attribute, container, prefix = nil )
      lay_out_attribute(attribute, container, prefix)
      container.add_field Field.new(container, make_name("present", make_name(attribute.name, prefix)), nil, boolean_field_type, "not null")
   end

   def self.lay_out_volatile_attribute( attribute, container, prefix = nil )
      nil
   end
   

   def self.lay_out_type( type, container, name = nil )
      fail "no lay_out support for #{type.class.name}"
   end
   
   def self.lay_out_reference_type( type, container, name = nil )
      warn_once("TODO: reference field null/default handling")
      
      if referenced_table = container.schema.tables[type.entity_name.to_s.identifier_case] then
         container.add_field ReferenceField.new(container, name, referenced_table, true, false)
      else
         fail "reference to un-laid-out table -- how is this possible?"
      end
   end

   def self.lay_out_identifier_type( type, container, name = nil )
      if referenced_table = container.schema.tables[type.entity_name.to_s.identifier_case] then
         container.add_field ReferenceField.new(container, name, referenced_table, false, true)
      else
         fail
      end
   end

   def self.lay_out_scalar_type( type, container, name = nil )
      container.add_field Field.new(container, name, type, scalar_field_type(type))
   end

   def self.lay_out_tuple_type( type, container, prefix = nil )
      lay_out(type.tuple, container, prefix)
   end
   
   def self.lay_out_collection_type( type, container, prefix = nil )
      container.define_table(prefix).tap do |table|
         table.add_field ReferenceField.new(table, container.id_field.name, container, false, true)
         if type.member_type.is_a?(Schemaform::Schema::ReferenceType) then
            referenced_name = type.member_type.referenced_entity.id
            referenced_name = make_name(referenced_name, prefix) if container.id_field.name == referenced_name
            lay_out(type.member_type, table, referenced_name)
         else 
            lay_out(type.member_type, table, prefix)
         end
      end
   end
   
   def self.lay_out_list_type( type, container, prefix = nil )
      lay_out_collection_type(type, container, prefix).tap do |collection_table|
         container.add_field ReferenceField.new(container, make_name("first", prefix), collection_table, true, false)
         container.add_field ReferenceField.new(container, make_name("last" , prefix), collection_table, true, false)

         collection_table.add_field ReferenceField.new(collection_table, make_name("next"    , prefix), collection_table, true, false)
         collection_table.add_field ReferenceField.new(collection_table, make_name("previous", prefix), collection_table, true, false)
      end
   end
   
   def self.lay_out_user_defined_type( type, container, prefix = nil )
      lay_out(type.base_type, container, prefix)
   end

   def self.lay_out_unknown_type( type, container, prefix = nil )
      container.top.describe
      fail
   end




   def self.scalar_field_type( sf_type )
      case sf_type
      when Schemaform::Schema::StringType
         if sf_type.typeof?(sf_type.schema.text_type) then
            text_field_type(sf_type.length)
         else
            "blob"
         end
      when Schemaform::Schema::BooleanType
         boolean_field_type()
      when Schemaform::Schema::IntegerType
         integer_field_type(sf_type.range)
      when Schemaform::Schema::DateTimeType
         date_time_field_type()
      when Schemaform::Schema::EnumeratedType
         if sf_type.evaluated_type.is_a?(Schemaform::Schema::StringType) then
            text_field_type(sf_type.evaluated_type.length)
         else
            integer_field_type(sf_type.evaluated_type.range)
         end
      else
         fail sf_type.class.name
      end
   end
   
   def self.boolean_field_type()
      "integer"
   end
   
   def self.text_field_type( length = nil )
      (length.exists? && length > 0 && length < 256) ? "varchar(#{length})" : "text"
   end
   
   def self.integer_field_type( range )
      "integer"
   end

   def self.date_time_field_type()
      "datetime"
   end
   

   def self.make_name( name, prefix = nil )
      prefix ? prefix + "__" + name.to_s : name.to_s
   end
   

end # Driver
end # Generic
end # Adapters
end # Schemaform