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
# A field within a table.

module Schemaform
module Adapters
module Generic
class Field
   include QualityAssurance
   extend  QualityAssurance
      
   def initialize( table, name, type, *marks )
      @table     = table
      @name      = name
      @type      = table.adapter.type_manager.scalar_type(type)
      @marks     = marks
      @reference = @marks.select_first{|m| m.is_a?(ReferenceMark)}
   end
   
   attr_reader :table, :name, :type, :marks, :reference
   
   def reference?()
      !!@reference
   end
   
   
end # Field
end # Generic
end # Adapters
end # Schemaform
