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
   # Creates an Adapter::Schema for internal use.
   
   def define_schema( name )
      schema_class().new(name, self)
   end
   
   
   #
   # Lays out a Schema for use with the database. 
   
   def lay_out( definition )
      @monitor.synchronize do
         unless @schemas.member?(definition)
            schema_name = Name.build(*definition.path)
            @schemas[definition] = schema_class().new(schema_name, self).tap do |schema|

               #
               # Create master tables for each entity first. We need them in place for reference resolution.

               definition.entities.each do |entity|
                  schema.define_master_table(schema_name + entity.name, entity.id, schema.entity_tables[entity.base_entity]).tap do |table|
                     schema.entity_tables[entity] = table
                  end
               end

               #
               # Now, fill them in with the basic data structure. We do no optimization, yet, as we 
               # want the basic structure to be as stable as possible (ie. adding projections and such
               # shouldn't require rewriting the entire data set).

               definition.entities.each do |entity|
                  master_table = schema.entity_tables[entity]
                  entity.heading.attributes.each do |attribute|
                     next if attribute.name == entity.id
                     next if entity.base_entity && entity.base_entity.declared_heading.attribute?(attribute.name)

                     dispatch_lay_out(attribute, master_table)
                  end
               end
            end
         end
      end
      
      @schemas[definition]
   end


   def dispatch_lay_out(element, container, name = Name.empty, mappee = nil)
      send_specialized(:lay_out, element, container, name, mappee)
   end
   

   def lay_out_attribute(attribute, table, base_name, mappee = nil )
      dispatch_lay_out(attribute.type, table, base_name + attribute.name, attribute)
   end
   
   def lay_out_optional_attribute( attribute, table, base_name, mappee = nil )
      lay_out_attribute(attribute, table, base_name, attribute)
      table.map_optional_marker(attribute, table.define_field(base_name + attribute.name + "present", type_manager.boolean_type, RequiredMark.build()))
   end

   def lay_out_volatile_attribute( attribute, table, base_name, context = nil )
      warn_todo("what do we do about mapping volatile attributes?")
      # volatile attributes are not stored
   end


   def lay_out_tuple( tuple, table, base_name, mappee )
      attribute_mappings = {}
      tuple.attributes.each do |attribute|
         dispatch_lay_out(attribute, table, base_name)
         attribute_mappings[attribute.name] = table.attribute_mappings[attribute]
      end

      table.map_tuple_attribute(mappee, attribute_mappings)
   end
   
   

   def lay_out_type( type, table, field_name, mappee )
      fail "no lay_out support for #{type.class.name}"
   end
   
   def lay_out_reference_type( type, table, field_name, mappee )
      warn_todo("reference field null/default handling")

      assert(table.schema.entity_tables.member?(type.referenced_entity), "couldn't find a master table for entity [#{type.entity_name}]")
      table.map_reference_attribute(mappee, table.define_field(field_name, type_manager.identifier_type, ReferenceMark.build(table.schema.entity_tables[type.referenced_entity])))
   end

   def lay_out_identifier_type( type, table, field_name, mappee )
      warn_once("USED: Adapter.lay_out_identifier_type()")
      lay_out_reference_type(type, table, field_name, mappee)
   end

   def lay_out_scalar_type( type, table, field_name, mappee )
      table.map_scalar_attribute(mappee, table.define_field(field_name, type_manager.scalar_type(type)))
   end

   def lay_out_tuple_type( type, table, field_name, mappee )
      dispatch_lay_out(type.tuple, table, field_name, mappee)
   end
   
   def lay_out_user_defined_type( type, table, field_name, mappee )
      dispatch_lay_out(type.base_type, table, field_name, mappee)
   end

   def lay_out_unknown_type( type, table, field_name, mappee )
      fail
   end



   def lay_out_collection_type( type, table, field_name, mappee )
      table.define_child(field_name).tap do |member_table|
         child_name = type.member_type.naming_type? ? Name.empty() : Name.build("record", "value")
         dispatch_lay_out(type.member_type, member_table, child_name, mappee)
      end
   end
   
   def lay_out_set_type( type, table, field_name, mappee )
      lay_out_collection_type(type, table, field_name, mappee)           # Let the member type be mapped to our mappee
      table.map_set_attribute(mappee, table.attribute_mappings[mappee])  # Then replace the member-wise mapping with the set-wise one
   end
   
   def lay_out_list_type( type, table, field_name, mappee )
      lay_out_collection_type(type, table, field_name, mappee).tap do |member_table|  # Let the member type be mapped to our mappee
         field_type       = type_manager.identifier_type
         member_reference = ReferenceMark.build(member_table)
         
         table.map_list_attribute mappee, table.attribute_mappings[mappee],           # Then replace member-wise mapping with the list-wise one
            member_table.define_field(Name.build("record", "next"    ), field_type, member_reference),
            member_table.define_field(Name.build("record", "previous"), field_type, member_reference),
                   table.define_field(field_name + "first"   , field_type, member_reference),
                   table.define_field(field_name + "last"    , field_type, member_reference)
      end
   end


end # Adapter
end # Generic
end # Adapters
end # Schemaform
