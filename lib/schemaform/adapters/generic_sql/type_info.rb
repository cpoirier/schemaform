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
# Represents a SQL type within the system.

module Schemaform
module Adapters
module GenericSQL
class TypeInfo
      
   def initialize( type_manager, sql, index_width, quoted = false, properties = {}, &formatter )
      @type_manager = type_manager
      @sql          = sql
      @index_width  = index_width
      @quoted       = quoted
      @properties   = properties
      @formatter    = formatter
   end
   
   attr_reader :type_manager, :sql, :index_width, :properties
   
   def quoted?()    ; @quoted          ; end
   def indexable?() ; @index_width > 0 ; end
   
   def quote_literal( value )
      if value.nil? then
         "null"
      elsif value == [] then
         "?"
      elsif @quoted then
         @type_manager.adapter.quote_string(format_literal(value))
      else
         format_literal(value)
      end
   end
   
   def op_literal( op, value )
      if value.nil? then
         case op
         when "="        ; "is null"
         when "!=", "<>" ; "is not null"
         else fail("unsupported comparison to null #{op}") 
         end
      else
         "#{op} #{quote_literal(value)}"
      end
   end

   def format_literal( adapter, value )
      @formatter ? @formatter.call(value.to_s) : value.to_s
   end
   
   def description()
      @sql
   end
   
   def adapter()
      @type_manager.adapter
   end
   
end # TypeInfo
end # Adapters
end # GenericSQL
end # Schemaform
