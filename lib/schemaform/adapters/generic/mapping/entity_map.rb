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
   
   Link    = Struct.new(:from_table, :to_table, :via, :distance)
   Mapping = Struct.new(:attribute, :property, :field)

   def initialize( schema_map, entity, anchor_table, base_map = nil )
      @schema_map   = schema_map
      @entity       = entity
      @anchor_table = anchor_table
      @base_map     = base_map || @schema_map[entity.base_entity]
      @parent_links = {}                                             # child Table => Link
      @all_links    = Hash.new(){|hash, key| hash[key] = {}}         # descendent Table => { ancestor Table => Link }
      @mappings     = Hash.new(){|hash, key| hash[key] = {}}         # Schema::Attribute => { aspect => Field }
      @schema_map.register_table(anchor_table)
   end

   attr_reader :schema_map, :entity, :anchor_table, :base_map

   def link_child_to_parent( reference_field )
      child_table  = reference_field.table
      parent_table = reference_field.reference_mark.table
      link         = Link.new(child_table, parent_table, reference_field, 1)
      
      @parent_links[child_table] = link
      @all_links[child_table][parent_table] = link
      
      @schema_map.register_table(child_table)
   end
   
   def link_child_to_context( reference_field )
      child_table   = reference_field.table
      context_table = referenced_field.reference_mark.table

      distance = 1
      current_table = child_table
      while hit = @parent_links[current_table]
         break if hit.to_table == context_table
         distance += 1
      end
      
      if hit then
         @all_links[child_table][context_table] = Link.new(child_table, context_table, reference_field, distance)
      else
         fail "couldn't find context path from [#{child_table.name}] to [#{context_table.name}]"
      end
   end
   
   def link_field_to_attribute( field, attribute, aspect )
      @mappings[attribute][aspect] = field
   end
   
   def project( expressions )
      fields = expressions.collect{|e| @mappings[e.attribute][e.class]}.flatten.uniq.compact
      tables = fields.collect{|f| f.table}.flatten.uniq
      
   end

end # EntityMap
end # Generic
end # Adapters
end # Schemaform

