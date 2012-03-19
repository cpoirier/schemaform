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


#
# A field within a table.

module Schemaform
module Adapters
module GenericSQL
module TableParts
class Field
   include QualityAssurance
   extend  QualityAssurance
      
   def initialize( table, name, type_info, *marks )
      @table          = table
      @name           = name
      @quoted_name    = @table.adapter.quote_identifier(@name)
      @type_info      = table.adapter.type_manager.scalar_type(type_info)
      @marks          = marks
      @reference_mark = @marks.select_first{|m| m.is_a?(ReferenceMark)}
      
      unless @marks.any?{|mark| mark.is_a?(RequiredMark) || mark.is_an?(OptionalMark)}
         @marks.unshift(RequiredMark.new()) 
      end
   end
   
   attr_reader :table, :name, :quoted_name, :type_info, :marks, :reference_mark
   
   def reference?()
      !!@reference_mark
   end
   
   def referenced_field()
      @reference_mark.table.identifier
   end
   
   def name_width()
      @quoted_name.length
   end

   def type_width()      
      @type.sql.length
   end
   
end # Field
end # TableParts
end # GenericSQL
end # Adapters
end # Schemaform
