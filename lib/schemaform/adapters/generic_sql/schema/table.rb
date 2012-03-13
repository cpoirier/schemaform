#!/usr/bin/env ruby -KU
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



#
# A table, possibly nested, (for naming purposes only). 

module Schemaform
module Adapters
module GenericSQL
class Table
   include QualityAssurance
   extend  QualityAssurance
   
   attr_reader   :adapter, :name, :fields, :indices
   attr_accessor :identifier

   def define_field( name, type, *modifiers )
      @fields.register(@adapter.field_class.new(self, name, type, *modifiers))
   end
   
   def define_index( name, unique = false )
      @indices.register(@adapter.index_class.new(self, name, unique)).tap do |index|
         yield(index) if block_given?
      end
   end
   
   def define_reference_field( name, target_table, *marks )
      define_field(name, @adapter.type_manager.identifier_type, @adapter.build_reference_mark(target_table), *marks)
   end
   
   def define_identifier_field( name, *marks )
      define_field(name, @adapter.type_manager.identifier_type, @adapter.build_generated_mark(), *marks)
   end

   def install( connection )
      unless present?(connection)
         connection.execute(@adapter.render_sql_create(self))
      end
   end
   
   def name_width()
      @fields.collect{|field| field.name_width}.max()
   end
   
   def type_width()
      @fields.collect{|field| field.type_width}.max()
   end
   
   def to_sql_create( name_width = 0, type_width = 0 )
      @adapter.render_sql_create(self, name_width, type_width)
   end
   
   
   
protected

   def initialize( adapter, name )
      @adapter = adapter
      @name    = name
      @fields  = Registry.new(name.to_s, "a field" )
      @indices = Registry.new(name.to_s, "an index")
   end

   def present?( connection )
      warn_once("present query text should be moved to Adapter")
      begin
         connection.retrieve("SELECT * FROM #{@name} WHERE 1 = 0")
         return true
      rescue Error => e
         return false
      end
   end



   def []( *names )
      return self[names] unless names.length == 1
      
      names = names.first
      case names
      when "*"
         @children.members
      when Hash
         @children.select{|field| names.member?(field.name)}
      when Array
         [].tap do |fields|
            @children.each do |name, field|
               fields << field if names.member?(field.name)
            end
         end
      else
         [@children[names]]
      end
   end
   
   
   
   
end # Table
end # GenericSQL
end # Adapters
end # Schemaform


Dir[Schemaform.locate("field_marks/*.rb")].each{|path| require path}
