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
# Adds entry points to the Adapter that genereate SQL select statements.

module Schemaform
module Adapters
module GenericSQL
class Adapter
   
   class RelationNamer
      def initialize() ; @number = 0 ; end
      def next( increment = true ) 
         begin
            return "r#{@number + 1}"
         ensure
            @number += 1 if increment
         end
      end
   end
   
   
   #
   # Renders some Adapter object into a SQL select statement.
   
   def render_sql_query( object, printer = nil, namer = nil )      
      dispatch(:render_sql_query, object, printer ||= Printer.new(""), namer || RelationNamer.new())
      printer.stream
   end
   
   def render_sql_select( registry, printer, source_alias )
      printer.print("SELECT ", false)
      printer.indent do
         first = true
         registry.each do |name, formula|
            if first then
               first = false
            else
               printer.print(", ", false)
            end
         
            if formula == name then
               printer.print("#{source_alias}.#{name}", false)
            else
               render_sql_expression( formula, printer, source_alias )
               printer.print(" as #{name}", false)
            end
         end
      end
      printer.end_line()
   end

   def render_sql_query_restriction( restriction, printer, namer )
      namer.next(false).tap do |source_alias|
         render_sql_query(restriction.source, printer, namer)
         printer.print("WHERE ", false)
         printer.indent() do
            render_sql_expression(restriction.criteria, printer, source_alias)
         end
      end
   end
   
   
   def render_sql_query_entity( entity, printer, namer )
      warn_once("render_sql_query_entity needs to handle subtables", "BUG")
      namer.next.tap do |source_alias|
         render_sql_select(entity.fields, printer, source_alias)
         printer.print("FROM #{entity.entity_map.anchor_table.name} #{source_alias}")
      end
   end

   def render_sql_query_relation( relation, printer, namer )
      namer.next.tap do |source_alias|
         render_sql_select(relation.fields, printer, source_alias)
         printer.print("FROM (")
         render_sql_query(relation.source, printer, namer)      
         printer.print(") #{source_alias}")
      end
   end
   

   def render_sql_expression( expression, printer, source_alias )
      dispatch(:render_sql_expression, expression, printer, source_alias)
   end

   def render_sql_expression_field( field, printer, source_alias )
      printer.print("#{source_alias}.#{field.name}", false)
   end
   
   def render_sql_expression_parameter( parameter, printer, source_alias )
      printer.print("?", false)
   end
   
   def render_sql_expression_comparison( comparison, printer, source_alias )
      render_sql_expression(comparison.lhs, printer, source_alias)
      printer.print(" = ", false)
      render_sql_expression(comparison.rhs, printer, source_alias)
   end

   def render_sql_expression_and( expression, printer, source_alias, conjunction = "and" )
      if expression.clauses.length >= 1 then
         expression.clauses.each_with_index do |clause, index|
            printer.print(" #{conjunction} ", false) unless index == 0
            render_sql_expression(clause, printer, source_alias)
         end
      else
         printer.print("1 = 1", false)
      end
   end
   
   def render_sql_expression_or( expression, printer, source_alias )
      render_sql_expression_and( expression, printer, source_alias, "or" )
   end


end # Adapter
end # GenericSQL
end # Adapters
end # Schemaform
