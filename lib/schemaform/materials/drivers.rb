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

require "monitor"
require "sequel/extensions/inflector.rb"

require Schemaform.locate("schemaform/schema.rb")


module Schemaform
class Schema
   
   #
   # Creates contollers that representent and operate your entities and tuples at runtime. 
   # You should never need to call this directly.
   
   def build_controllers( container = Schemaform::MaterializedSchemas )
      @monitor.synchronize do
         @control_material = Materials::SchemaController.define("#{@name}_V#{@version}".intern, container).tap do |schema_controller|
            # @tuples.each do |tuple|
            #    tuple.materialize_controllers(schema_controller)
            # end

            @entities.each do |entity|
               entity.build_controllers(schema_controller)
            end
         end
      end
   end
   
   
   
   class Entity < Relation
      def connect( transaction )
         schema.build_controllers() unless @control_material
         @control_material.new(transaction)
      end
      
      def build_controllers( container )
         operations  = @operations
         projections = @projections
         keys        = @keys
         
         @control_material = Materials::EntityController.define(@name, container) do
            operations.each do |name, block|
               define_method(name, block)
            end
            
            keys.each do |key|
               define_method("get_by_#{key.name}".intern) do |*args|
                  fail
               end
               
               define_method("project_by_#{key.name}".intern) do |projection, *args|
                  fail
               end
               
               projections.each do |projection|
                  define_method("get_#{projection.name}_by_#{key.name}".intern) do |*args|
                     fail
                  end
               end
            end
         end
      end
   end
   
   
   

   # class Tuple < Element
   #    def materialize_controllers( into_module, name_override = nil )
   #       Materials::TupleController.define_subclass((name_override || @name).to_s.camelize.intern, into_module).tap do |tuple_class|
   #          @attributes.each do |attribute|
   #             attribute.materialize_controllers( tuple_class )
   #          end
   #       end
   #    end
   # end
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
   #       into.define_field(nil, schema.identifier_type)
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
   #       table = into.define_table(:members)
   #       if @member_type.is_a?(TupleType) then
   #          @member_type.lay_out(table)
   #       else
   #          group = table.define_group(:member)
   #          @member_type.lay_out(group)
   #       end
   #    end
   # end
   # 
   # class ListType < CollectionType
   #    def lay_out( into )
   #       super
   #       into.define_field(:first, schema.identifier_type)
   #       into.define_field(:last , schema.identifier_type)
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


#
# The namespace where the system materializes the Controllers.

module Schemaform
module MaterializedSchemas
end
end



Dir[Schemaform.locate("controllers/*.rb")].each{|path| require path}

