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

require Schemaform.locate("wrappers.rb")


module Schemaform
module Adapters
module GenericSQL
module Wrappers
   
   class Wrapper
      def lay_out()
      end
   end
   
   
   class Model
      class Schema
         def lay_out()
            @entities = {}
            @model.defined_entities.each do |entity|
               @entities[entity.name] = wrap(entity)
            end
            
            @entities.each do |name, wrapper|
               wrapper.lay_out()
            end
         end      
      end
      
      class Component
         def context()
            @context ||= wrap(@model.context)
         end
         
         def table()
            @table ||= context.table
         end
         
         def name()
            @name ||= context.name
         end         
      end
      
      class DefinedEntity
         def lay_out()
            table()
            @model.heading.attributes.each do |attribute|
               wrap(attribute).lay_out()
            end
         end
         
         def table()
            @table ||= @adapter.define_linkable_table(@adapter.create_name(@model.name), @model.base_entity.nil? ? nil : wrap(@model.base_entity).table)
         end
         
         def name()
            @name ||= @adapter.create_name()
         end
      end
      
      class Tuple
      end
      
      class Attribute
         def lay_out()
            wrap(@model.type).lay_out(table, name)
         end
         
         def name()
            @name ||= context.name + @model.name
         end
      end
      
      class Type
         def lay_out( table, name )
            Schemaform.debug.dump(self.class.name)
         end
      end
      
      class ScalarType
         def lay_out( table, name )
            table.define_field(name, @adapter.type_manager.scalar_type(@model))
         end
      end
      
      class UserDefinedType
         def lay_out( table, name )
            wrap(@model.evaluated_type).lay_out(table, name)
         end
      end
      
      class TupleType
         def lay_out( table, name )
            wrap(@model.tuple).lay_out()
         end
      end
      
      class SetType
         def lay_out( table, name )
            
         end
         
         def table()
            @table ||= @adapter.define_linkable_table(context.table.name + name, context.table)
         end
         
         def name()
            @name ||= @adapter.create_name()
         end
      end
      
      

      
      # class OptionalAttribute
      #    def lay_out()
      #       
      #    end
      # end
      # 
      # 
      # def lay_out_attribute( attribute, builder, before = true )
      #      builder.with_attribute(attribute) do
      #         yield if block_given? && before
      #         send_specialized(:lay_out, attribute.type, builder)
      #         yield if block_given? && !before
      #      end
      #   end
      # 
      #   def lay_out_optional_attribute( attribute, builder )
      #      lay_out_attribute(attribute, builder, true) do
      #         builder.define_meta(Language::Productions::PresentCheck, "is_present", type_manager.boolean_type, build_required_mark())
      #      end
      #   end
      
      
   end # Model
   
   
   class Productions
   end # Productions


end # Wrappers
end # GenericSQL
end # Adapters
end # Schemaform