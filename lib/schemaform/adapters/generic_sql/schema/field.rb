#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
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
# A field within a table.

module Schemaform
module Adapters
module GenericSQL
class Field
   include QualityAssurance
   extend  QualityAssurance
      
   def initialize( table, name, type, *marks )
      @table          = table
      @name           = name
      @type           = table.adapter.type_manager.scalar_type(type)
      @marks          = marks
      @reference_mark = @marks.select_first{|m| m.is_a?(ReferenceMark)}
      
      unless @marks.any?{|mark| mark.is_a?(RequiredMark) || mark.is_an?(OptionalMark)}
         @marks.unshift(RequiredMark.new()) 
      end
   end
   
   attr_reader :table, :name, :type, :marks, :reference_mark
   
   def reference?()
      !!@reference_mark
   end
   
   def referenced_field()
      @reference_mark.table.identifier
   end
   
   def name_width()
      @name.to_s.length
   end

   def type_width()      
      @type.sql.length
   end
   
end # Field
end # GenericSQL
end # Adapters
end # Schemaform
