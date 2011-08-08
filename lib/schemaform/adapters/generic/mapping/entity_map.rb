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
# Captures informtion about how a Schema::Entity is mapped into Tables and Fields.

module Schemaform
module Adapters
module Generic
class EntityMap

   def initialize( schema_map, entity, anchor_table, base_map = nil )
      @schema_map   = schema_map
      @entity       = entity
      @anchor_table = anchor_table
      @base_map     = base_map || @schema_map[entity.base_entity]
      @links        = {}  
      
      @schema_map.register_table(anchor_table)
      
      
      
      
      # @ancestors    = base_map ? @base_map.ancestors + [@base_map] : []

      # @links = {}  parent_table => [child_tables]
      #              parent_table => { child_table => link info }
      #              
      #        OR    child_table => { parent_table => link info }
      #        
      # ALSO
      # if you add a link to an identifier that is itself a reference, you should add a synonym link that skips the intermediary.
      #    
      # You are building a DAG. Don't you already have one of those written?
      # 
      # table => 
   end

   attr_reader :schema_map, :entity, :anchor_table, :base_map

   def link_child_to_parent( reference_field )
      child_table  = reference_field.table
      parent_table = reference_field.reference_mark.table
      
      @links[child_table] = [parent_table, reference_field]
      @schema_map.register_table(child_table)
   end
   
   def link_child_to_context( reference_field )
      child_table   = reference_field.table
      context_table = referenced_field.reference_mark.table
      
      warn_todo("count distance from child to context")
      @links[child_table] = [context_table, reference_field]
   end



#    
#    def add_table( table, parent_table, link_field, table.identifier, entity_map.ancestors.count )
#       
#    end
#    
#    
#    
#    
#    
#    
#    
#    def capture_tuple_attribute( attribute )
#       capture_attribute(attribute) do
#          @attribute_mappings[attribute] = []
#          yield
#       end
#    end
#    
#    alias capture_scalar_attribute capture_attribute
#    alias capture_set_attribute    capture_attribute
#    alias capture_list_attribute   capture_attribute
#    
#    def define_field( field, purpose = nil )
#       @capturing.each do |context|
#          context << attribute if context.is_an?(Array)
#       end
#       
#       #
#       # Given a new ParentLink, calculates all potential JoinPaths that can be used to 
#       # assemble a subset of the originating Entity.
# 
#       def add_path( field, structural_link )
#          @parent = structural_link.table if structural_link.direct_parent?
#          @parent.paths.each do |parent_path|
#             @paths << parent_path + 
#          end
#       end
# 
# 
#       
#       WORKING HERE -- FIGURE OUT IF WE WOULD STORE EVERY FIELD IN ALL CONTEXTS
#       
#       if @attribute_mappings.member?(@capturing)
#    end
#    
# protected
# 
#    def capture_attribute( attribute )
#       @capturing.push(attribute)
#       begin      
#          @attribute_mappings[attribute] = {}
#          yield
#       ensure
#          @capturing.pop()
#       end
#    end
# 

end # EntityMap
end # Generic
end # Adapters
end # Schemaform

