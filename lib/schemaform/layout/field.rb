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
# A field within a table. Unlike attributes in the definition series, fields have only a name
# and a type.

module Schemaform
module Layout
class Field < Component

   def initialize( context, name, type, references_field = nil )
      super( context, name )
      @type = type
      @references_field = references_field
   end
   
   attr_reader :type, :references_field
   alias :tables :children
   
   def define_table( name )
      add_child Table.new(self, name)
   end
   
   def describe( indent = "", name_override = nil, suffix = nil )
      super indent, name_override, @type.description
   end
   

end # Field
end # Layout
end # Schemaform
