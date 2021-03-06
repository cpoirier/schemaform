#!/usr/bin/env ruby
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2012 Chris Poirier
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

require Schemaform.locate("schemaform/model/schema.rb")

#
# Defines wrappers for the Model classes.

module Schemaform
module Adapters
module GenericSQL
module Wrappers
class Model
   
   class Wrapper < Wrapper      
   end

   
   #
   # Create wrapper classes for all Model classes.
   
   extend Common
   Schemaform::Model.constants(false).each do |constant|
      create_wrapper_class(Schemaform::Model.const_get(constant))
   end

   
   #
   # Customize those wrappers that need it.
   
   class Schema
      def initialize( context, model )
         super(context, model)
         @entities = {}

         model.entities.each do |entity|
            @entities[entity] = wrap(entity)
         end
      end
      
      attr_reader :entities
      
      def lay_out()
         @entities.each do |model, wrapper|
            wrapper.lay_out()
         end
      end
      
      def table()
         nil
      end
      
      def name()
         @name ||= @adapter.create_name(@model.name)
      end      
   end
   
   
   class Component
      def table()
         @table ||= context.table
      end

      def name()
         @name ||= context.name
      end
      
      def schema()
         @schema ||= find_context{|c| c.is_a?(Schema)}
      end
   end
   
   
   class DefinedEntity
      def initialize( context, model )
         super(context, model)
         @heading = wrap(model.heading)
      end
      
      attr_reader :heading
      
      def lay_out()
         table()
         @heading.attributes.each do |model, wrapper|
            next if @model.base_entity.exists? && @model.base_entity.heading.attribute?(model.name)
            wrapper.lay_out()
         end
      end

      def table()
         @table ||= @adapter.define_linkable_table(@context.name + @model.name, @model.base_entity.nil? ? nil : schema.entities[@model.base_entity].table)
      end

      def name()
         @name ||= @adapter.create_name()
      end      
   end
   
   
   class Tuple
      def initialize( context, model )
         super(context, model)
         @attributes = {}
         
         model.attributes.each do |attribute|
            @attributes[attribute] = wrap(attribute)
         end
      end
      
      attr_reader :attributes
      
      def lay_out()
         @attributes.each do |model, wrapper|
            wrapper.lay_out()
         end
      end
   end
   
   
   class Attribute
      def initialize( context, model )
         super(context, model)
         @type    = wrap(model.type)
         @formula = wrap(model.instance_eval{@formula})       # We go direct because we don't want to trigger any new processing
      end
      
      attr_reader :type
      
      def writable?()
         @model.writable?
      end

      def required?()
         @model.required?
      end

      def derived?()
         @model.derived?
      end

      def lay_out()
         @type.lay_out()
      end

      def name()
         @name ||= context.name + @model.name
      end
   end
   
   
   class OptionalAttribute
      def lay_out()
         super
         table.define_field(present_flag_name, @adapter.type_manager.boolean_type)
      end
      
      def present_flag_name()
         @present_flag_name ||= @adapter.create_present_name(name)
      end
   end


   class DerivedAttribute
      def lay_out()
         @formula.lay_out()
      end
   end


   class Type
      def lay_out()
         Schemaform.debug.dump("skipping unsupported type #{self.class.name} in #{table.name}.#{name}")
      end
   end


   class ScalarType
      def lay_out()
         table.define_field(name, @adapter.type_manager.scalar_type(@model))
      end
   end

      
   class IndirectType
      def initialize( context, model )
         super(context, model)
         @element = wrap(model.element)
      end
      
      attr_reader :element
      
      def lay_out()
         @element.lay_out()
      end
   end
   
   
   class TupleType
      alias :tuple :element
   end
   
   
   class UserDefinedType
      def initialize( context, model )
         super(context, model)
         @evaluated_type = wrap(@model.evaluated_type)
      end
      
      attr_reader :evaluated_type
      
      def lay_out()
         @evaluated_type.lay_out()
      end      
   end
   
   
   class EntityReferenceType
      def initialize( context, model )
         super(context, model)
      end

      def referenced_entity
         schema.entities[@model.referenced_entity]
      end
      
      def lay_out()
         warn_todo("reference field null/default handling")
         
         marks = []
         marks << (find_context{|c| c.is_an?(Attribute)}.required? ? table.create_required_mark : table.create_optional_mark)
         marks << table.create_reference_mark(referenced_entity.table, true)

         table.define_field(name, @adapter.type_manager.identifier_type, *marks)
      end      
   end
   
   
   class CollectionType
      def initialize( context, model )
         super(context, model)
         @member_type = wrap(@model.member_type)
      end
      
      def table()
         @table ||= @adapter.define_linkable_table(context.table.name + context.name, context.table)
      end

      def name()         
         @name ||= @model.naming_type? ? @adapter.create_name() : @adapter.create_internal_name("value")
      end
   end


   class SetType
      def lay_out()
         @member_type.lay_out()
      end
   end


   class ListType
      def lay_out()
         @context.table.use do |outer|
            outer.define_field(@adapter.create_internal_name(@context.name, "first"), @adapter.type_manager.identifier_type, table.create_optional_mark, outer.create_reference_mark(table, true))
            outer.define_field(@adapter.create_internal_name(@context.name, "last" ), @adapter.type_manager.identifier_type, table.create_optional_mark, outer.create_reference_mark(table, true))
            outer.define_field(@adapter.create_internal_name(@context.name, "index"), @adapter.type_manager.text_type)
         end
         
         @member_type.lay_out()
         
         table.use do |inner|
            inner.define_field(@adapter.create_internal_name(name, "next"    ), @adapter.type_manager.identifier_type, inner.create_optional_mark, inner.create_reference_mark(inner, true))
            inner.define_field(@adapter.create_internal_name(name, "previous"), @adapter.type_manager.identifier_type, inner.create_optional_mark, inner.create_reference_mark(inner, true))
         end
      end
   end

   

end # Model
end # Wrappers
end # GenericSQL
end # Adapters
end # Schemaform
