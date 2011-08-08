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
      @attribute_mappings = {}
      @schema_map.register_table(anchor_table)
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
   
   def link_field_to_attribute( field, attribute )
      @attribute_mappings[attribute] = [] unless @attribute_mappings.member?(attribute)
      @attribute_mappings[attribute] << field
   end

end # EntityMap
end # Generic
end # Adapters
end # Schemaform

