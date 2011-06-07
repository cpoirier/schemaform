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

require "monitor"
require "sequel/extensions/inflector.rb"

require Schemaform.locate("schemaform/schema.rb")
require Schemaform.locate("tuple.rb")
require Schemaform.locate("entity_tuple.rb")


module Schemaform
class Schema
   
   @@materialization_monitor    = Monitor.new()
   @@materialization_namespaces = {} 
   
   #
   # Creates runtime classes for your Schema within the module you specify.
   
   def materialize( into_module )
      type_check(:into_module, into_module, Module)
      
      #
      # The public Tuple and Entity class are materialized into the supplied into_module 
      # (meaning you can materialize them in multiple places). However, these components are 
      # backed by descriptors that are global -- one set per Schema. We materialize these 
      # descriptors into a private namespace that we create within the Schemaform hierarchy.
      # Each Schema is associated with a namespace (generally the Registry it is stored in,
      # but it could be any Object), and we assign a module name to each such namespace on a
      # first-come, first-serve basis.

      unless controller_module = @@materialized_namespaces.fetch(@namespace, nil)
         controller_module = Module.new()
         
         @@materialization_monitor.synchronize do
            module_index = @@materialized_namespaces.length
            module_name  = "Controllers#{module_index > 0 ? module_index : ""}"
            
            @@materialized_namespaces[@namespace] = Schemaform.const_set(module_name, controller_module)
         end
         
         materialize_controllers( controller_module )
      end
      
      #
      # With the descriptors materialized, we now create the public Tuple and Entity classes.
      
      @entities.each do |entity|
         entity.materialize(into_module, controller_module)
      end
      
      @tuples.each do |tuple|
         tuple.materialize(into_module, controller_module)
      end
   end
   
   
   def materialze_controllers( into_module )
      schema_class = Materials::SchemaController.define(@name, into_module)
      
      @entities.each do |entity|
         entity.materialize_controllers(schema_class)
      end
      
      @tuples.each do |tuple|
         tuple.materialize_controllers(schema_class)
      end      
   end
   
   
   
   
   
   class Entity < Relation
      def materialize( into_module, controller_module )
         Runtime::Tuple.define_subclass(@declared_heading.name, into_module) do |tuple_class|
            
         end
      end

      def materialize_controllers( into_module )
         tuple_class = @heading.materialize_controllers(into_module, @declared_heading.name)
         Materials::EntityController.define_subclass(@name, tuple_class, into_module)
      end
      
   end
   

   class Tuple < Element
      def materialize_controllers( into_module, name_override = nil )
         Materials::TupleController.define_subclass((name_override || @name).to_s.camelize.intern, into_module).tap do |tuple_class|
            @attributes.each do |attribute|
               attribute.materialize_controllers( tuple_class )
            end
         end
      end
   end
   
   
   class WriteableAttribute


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
   #       type_check(:into, into, Layout::SQL::Group)
   #       warn_once("TODO: reference field link")
   #       into.define_field(nil, schema.identifier_type)
   #    end
   # end
   # 
   # class ScalarType < Type
   #    def lay_out( into )         
   #       type_check(:into, into, Layout::SQL::Group)
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
   #       type_check(:into, into, Layout::SQL::Group)
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
   #       type_check(:into, into, Layout::SQL::Group)
   #       into.top.describe
   #       fail
   #    end
   # end
   

end # Schema
end # Schemaform


# ["sql"].each do |directory|
#    Dir[Schemaform.locate("#{directory}/*.rb")].each do |path|
#       require path
#    end
# end
