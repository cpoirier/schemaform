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
# A component within the Adapters tree.

module Schemaform
module Adapters
module Generic
class Component
   include QualityAssurance

   def initialize( context, name )
      @context  = context
      @schema   = context ? context.schema : self
      @name     = name
      @children = nil
   end
   
   attr_reader :context, :name, :children, :schema
   
   def sql_name()
      quote_identifier(@name)
   end
   
   def quote_string( string )
      @schema.adapter.quote_string(string)
   end
   
   def quote_identifier( identifier )
      @schema.adapter.quote_identifier(identifier)
   end
   
   def make_name( name, prefix = nil )
      @schema.adapter.make_name(name, prefix)
   end
   
   def top()
      @context ? @context.top : self
   end

   def add_child( child )
      @children = Registry.new("#{self.class.name} #{@name}") if @children.nil?
      @children.register child
      child
   end
   
   def define_table( name, id_name = nil, id_table = nil )
      @context.define_table(@schema.adapter.make_name(name.to_s, @name.to_s), id_name, id_table)
   end
   
   def define_owner_fields( into )
      @context.define_owner_fields(into)
   end

   def describe( indent = "", name_override = nil, suffix = nil )
      puts "#{indent}#{self.class.name.split("::").last}: #{name_override || @name}#{suffix ? " " + suffix : ""}"
      if @children then
         child_indent = indent + "   "
         @children.each do |child|
            child.describe(child_indent)
         end
      end
   end
   
   def to_sql_create()
      fail_unless_overridden self, :to_sql_create
   end
   
   
end # Component
end # Generic
end # Adapters
end # Schemaform


