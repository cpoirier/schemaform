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

require Schemaform.locate("relation.rb")


#
# A table, possibly nested, (for naming purposes only). 

module Schemaform
module Adapters
module GenericSQL
class Table < Relation
   
   attr_reader   :name, :quoted_name, :fields, :indices
   attr_accessor :identifier

   def define_field( name, type, *marks )
      @fields.register(create_field(name, type, *marks))
   end
   
   # def define_index( name, unique = false )
   #    @indices.register(@adapter.index_class.new(self, name, unique)).use do |index|
   #       yield(index) if block_given?
   #    end
   # end
   
   def define_reference_field( name, target_table, *marks )
      define_field(name, @adapter.type_manager.identifier_type, create_reference_mark(target_table), *marks)
   end
   
   def define_identifier_field( name, *marks )
      define_field(name, @adapter.type_manager.identifier_type, create_generated_mark(), *marks)
   end
   
   def install( connection )
      unless present?(connection)
         connection.execute(render_sql_create())
      end
   end
   
   
   

   # =======================================================================================
   #                                           SQL
   # =======================================================================================
   
   def as_query()
      @query ||= @adapter.create_query(self)
   end

   def render_sql_update( set_fields, key_fields )
      set_fields = @fields.filter(set_fields)
      key_fields = @fields.filter(key_fields)
      
      sets = set_fields.collect{|k, v| quote_pair(k, v)}
      keys = key_fields.collect{|k, v| quote_pair(k, v)}
      
      block_given? ? yield(sets, keys) : "UPDATE #{quoted_name()} SET\n  #{sets.join("\n, ")}\nWHERE #{keys.join("\n  AND ")};"
   end
   
   def render_sql_delete( key_fields )
      keys = @fields.filter(key_fields).collect{|k, v| quote_pair(k, v)}
      block_given? ? yield(keys) : "DELETE FROM #{quoted_name()}\nWHERE #{keys.join("\n  AND ")};"
   end
   
   def render_sql_create( name_width = 0, type_width = 0, if_not_exists = false )
      warn_todo("add keys and indices to table create")
      
      name_width ||= @fields.name_width()
      type_width ||= @fields.type_width()
      
      fields  = @fields.collect{|field| render_sql_create_field(field, name_width, type_width)}
      keys    = []
      clauses = fields + keys
      
      block_given? ? yield(fields, keys) : "CREATE TABLE #{if_not_exists ? "IF NOT EXISTS " : ""}#{quoted_name()}\n(\n   #{clauses.join(",\n   ")}\n);"
   end
   
   def render_sql_create_field( field, name_width, type_width )
      modifiers = field.marks.collect{|mark| send_specialized(:render_sql_create, mark)}
      [field.quoted_name.ljust(name_width+3), field.type_info.sql.ljust(type_width+1), *modifiers].join(" ")
   end
   
   def render_sql_create_generated_mark( mark )
      "AUTOINCREMENT"
   end
   
   def render_sql_create_primary_key_mark( mark )
      "PRIMARY KEY"
   end
   
   def render_sql_create_required_mark( mark )
      "NOT NULL"
   end
   
   def render_sql_create_optional_mark( mark )
      "    NULL"
   end
   
   def render_sql_create_reference_mark( mark )
      clauses = []
      clauses << "REFERENCES #{mark.table.quoted_name} (#{mark.table.identifier.quoted_name})"
      clauses << "DEFERRABLE INITIALLY DEFERRED" if mark.deferrable?
      clauses.join(" ")
   end
   
   
   
   # =======================================================================================
   #                                   Object Instantiation
   # =======================================================================================
   
   def create_field( name, type, *marks )
      TableParts::Field.new(self, name, type, *marks)
   end
   
   def create_index( name, unique = false )
      TableParts::Index.new(self, name, unique)
   end

   def create_generated_mark()
      TableParts::GeneratedMark.build()
   end
   
   def create_primary_key_mark()
      TableParts::PrimaryKeyMark.build()
   end
   
   def create_required_mark()
      TableParts::RequiredMark.build()
   end
   
   def create_reference_mark( table, deferrable = false )
      TableParts::ReferenceMark.build(table, deferrable)
   end
   
   
   
   
protected

   def initialize( adapter, name )
      super(adapter)

      @name        = name
      @quoted_name = quote_identifier(@name)
      @fields      = FieldRegistry.new(name.to_s, "a field")
      @indices     = Registry.new(name.to_s, "an index")
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
   
   def quote_pair( name, value )
      "#{quote_identifier(name)} = #{@fields[name].quote_literal(value)}"
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
         [].use do |fields|
            @children.each do |name, field|
               fields << field if names.member?(field.name)
            end
         end
      else
         [@children[names]]
      end
   end
   
   
   
   
   class FieldRegistry < Registry
      
      def name_width()
         members.collect{|field| field.name_width}.max()
      end
      
      def type_width()
         members.collect{|field| field.type_width}.max()
      end

   end
   
end # Table
end # GenericSQL
end # Adapters
end # Schemaform

Dir[Schemaform.locate("table_parts/*.rb")].each{|path| require path}
