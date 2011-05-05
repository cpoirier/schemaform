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
# A component within the Layout tree.

module Schemaform
module Layout
module SQL
class Component
   include QualityAssurance

   def initialize( context, name )
      @context  = context
      @schema   = context ? context.schema : self
      @name     = name
      @children = nil
   end
   
   attr_reader :context, :name, :children, :schema

   def define_group( name )
      add_child Group.new(self, name)
   end
   
   def add_child( child )
      @children = {} if @children.nil?
      @children[child.name] = child
      child
   end
   
   def define_owner_fields( into )
      @context.define_owner_fields(into)
   end

   def describe( indent = "", name_override = nil, suffix = nil )
      puts "#{indent}#{self.class.name.split("::").last}: #{name_override || @name}#{suffix ? " " + suffix : ""}"
      if @children then
         child_indent = indent + "   "
         @children.each do |name, child|
            child.describe(child_indent)
         end
      end
   end
   
   
end # Component
end # SQL
end # Layout
end # Schemaform

require Schemaform.locate("group.rb")

