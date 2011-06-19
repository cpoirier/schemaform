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

require "sequel/extensions/inflector.rb"
require Schemaform.locate("schemaform/schema.rb")


module Schemaform
class Schema
   def lay_out( database = nil )
      database_type = database ? database.type : nil

      @adapters = {} unless defined?(@adapters)
      unless @adapters.member?(database_type)
         @adapters[database_type] = case database_type
         when :sqlite
            Schemaform::Adapters::SQLite::Driver.lay_out_schema(self)
         else
            Schemaform::Adapters::Generic::Driver.lay_out_schema(self)
            # fail "lay_out not supported for database type #{database.type}"
         end
      end
      
      @adapters[database_type]
   end
   
   
   # class Entity < Relation
   #    def lay_out( into = nil )
   #       if into then
   #          id_name = id()
   #          table   = into.define_table(name, id_name)
   #          @heading.attributes.each do |attribute|
   #             next if attribute.name == id_name
   #             next if @base_entity && @base_entity.declared_heading.member?(attribute.name)
   #             
   #             attribute.lay_out(table)
   #          end
   #       else
   #          fail_todo "what here?"
   #       end
   #    end
   # end
   # 
   # 
   # class Tuple < Element
   #    def lay_out( into = nil )
   #       if into then
   #          @attributes.each do |attribute|
   #             attribute.lay_out(into)
   #          end
   #       else
   #          fail_todo "what here?"
   #       end
   #    end
   # end
   # 
   # 
   # class Attribute < Element
   #    def lay_out( into = nil )
   #       if into then
   #          into.define_group(self.name).tap do |group|
   #             @lay_out = group
   #             type.lay_out(group)
   #          end
   #       else
   #          schema.lay_out() if @lay_out.nil?
   #          @lay_out
   #       end
   #    end
   # end
   # 
   # 
   # class OptionalAttribute < WritableAttribute
   #    def lay_out( into = nil )
   #       group = super(into)
   #       group.define_field(:__present, schema.boolean_type) if into
   #    end   
   # end 
   # 
   # 
   # class VolatileAttribute < DerivedAttribute
   #    def lay_out( into = nil )
   #       nil
   #    end
   # end 
   # 
   # 
   # class Type < Element
   #    def lay_out( into )
   #       fail "no lay_out support for #{self.class.name}"
   #    end
   # end
   # 
   # class ReferenceType < Type
   #    def lay_out( into )
   #       type_check(:into, into, Adapters::SQL::Group)
   #       warn_once("TODO: reference field link")
   #       into.define_field(nil, schema.identifier_type, @entity_name)
   #    end
   # end
   # 
   # class IdentifierType < Type
   #    def lay_out( into )
   #       type_check(:into, into, Adapters::SQL::Group)
   #       into.define_field(nil, self)
   #    end
   # end
   # 
   # class ScalarType < Type
   #    def lay_out( into )         
   #       type_check(:into, into, Adapters::SQL::Group)
   #       into.define_field(nil, self)
   #    end
   # end
   # 
   # class TupleType < Type
   #    def lay_out( into )
   #       @tuple.lay_out(into)
   #    end
   # end
   # 
   # class CollectionType
   #    def lay_out( into )
   #       type_check(:into, into, Adapters::SQL::Group)
   #       into.define_table(:members).tap do |table|
   #          if @member_type.is_a?(TupleType) then
   #             @member_type.lay_out(table)
   #          else
   #             group = table.define_group(:member)
   #             @member_type.lay_out(group)
   #          end
   #       end
   #    end
   # end
   # 
   # class ListType < CollectionType
   #    def lay_out( into )
   #       collection_table = super
   #       into.define_field(:first, schema.identifier_type)
   #       into.define_field(:last , schema.identifier_type)
   #       collection_table.define_field(:__next    , schema.identifier_type, collection_table.id_field)
   #       collection_table.define_field(:__previous, schema.identifier_type, collection_table.id_field)
   #    end
   # end
   # 
   # class UnknownType < Type
   #    def lay_out( into )
   #       type_check(:into, into, Adapters::SQL::Group)
   #       into.top.describe
   #       fail
   #    end
   # end
   

end # Schema
end # Schemaform


Dir[Schemaform.locate("*/*.rb")].each{|path| require path}
