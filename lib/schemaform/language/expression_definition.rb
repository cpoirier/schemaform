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


module Schemaform
module Language
module FormulaDefinition
   extend QualityAssurance
   
   def self.if_then_else( condition, true_branch, false_branch = nil )
      condition    = FormulaCapture.capture(condition   )
      true_branch  = FormulaCapture.capture(true_branch )
      false_branch = FormulaCapture.capture(false_branch)

      # assert(condition.get_type.boolean_type, "the if_then_else condition must have a boolean type")

      production = Productions::IfThenElse.new(condition, true_branch, false_branch)
      FormulaCapture.merge_types(true_branch.get_type, false_branch.get_type).placeholder(production)
   end
   
   def self.all( entity_name )
      FormulaCapture.resolution_scope do |schema|
         assert(schema.entities.member?(entity_name), "unable to find entity [#{entity_name}] in resolution scope")
         schema.entities[entity_name].placeholder 
      end
   end
   
   def self.parameter( number )
      Parameter.new(number)
   end
   
   def self.and!( *clauses )
      boolean_type = FormulaCapture.resolve_type(:boolean)
      
      check do
         clauses.each do |clause| 
            type_check(:clause, clause, Placeholder)
            assert(boolean_type.assignable_from?(clause.get_type), "expected boolean expression for logical and, found #{clause.get_type.description}")
         end
      end
      
      boolean_type.placeholder(Productions::And.new(clauses))
   end

   def self.or!( *clauses )
      boolean_type = FormulaCapture.resolve_type(:boolean)
      clauses = clauses.collect do |clause| 
         assert(boolean.assignable_from?(clause.get_type), "expected boolean expression for logical and, found #{clause.get_type.description}")
      end
      
      boolean_type.placeholder(Productions::Or.new(clauses))
   end
   
   def self.not!( clause )
      fail_todo
      # 
      # boolean = FormulaCapture.resolve_type(:boolean)
      # clause  = FormulaCapture.capture(clause).tap do |captured|
      #    assert(boolean.assignable_from?(captured.get_type), "expected boolean expression for logical not, found #{lhs.get_type.description}")
      # end
      # 
      # boolean.capture(Productions::Not.new(clause))
   end

   
end # FormulaDefinition
end # Language
end # Schemaform

