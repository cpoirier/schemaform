#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2010 Chris Poirier
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

require Schemaform.locate("component.rb")


#
# Acts like both a field and a table, for the purpose of grouping a set of fields and subtables 
# together and applying a prefix to the names.

module Schemaform
module Layout
module SQL
class Group < Component

   def initialize( context, name )
      super(context, name)
      @fields = {}
   end
   
   attr_reader :fields
   alias :tables :children

   def define_field( name, type, references_field = nil )
      add_child Field.new(self, name, type, references_field)
   end
   
   def define_table( name )
      add_child Table.new(self, name)
   end
   
   
   # def describe( indent = "", name_override = nil, suffix = nil )
   #    if @children then
   #       case @children.count
   #       when 0
   #          return
   #       when 1
   #          @children.each do |name, child|
   #             child.describe(indent, @name)
   #          end
   #       else
   #          super
   #       end
   #    end
   # end
   

end # Group
end # SQL
end # Layout
end # Schemaform
