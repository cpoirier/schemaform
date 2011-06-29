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
module ExpressionDefinition
   extend QualityAssurance
   
   def self.if_then_else( condition, true_branch, false_branch = nil )
      condition    = ExpressionCapture.capture(condition   )
      true_branch  = ExpressionCapture.capture(true_branch )
      false_branch = ExpressionCapture.capture(false_branch)

      # assert(condition.type.boolean_type, "the if_then_else condition must have a boolean type")

      production = Productions::IfThenElse.new(condition, true_branch, false_branch)
      ExpressionCapture.merge_types(true_branch, false_branch).capture(production)
   end
   
   
end # ExpressionDefinition
end # Language
end # Schemaform

