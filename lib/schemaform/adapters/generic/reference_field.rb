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

require Schemaform.locate("field.rb")


#
# An auto-generated identifier field within a table.

module Schemaform
module Adapters
module Generic
class ReferenceField < Field

   def initialize( context, name, referenced_table, deferrable, required, field_type = "integer" )
      modifiers = []
      modifiers << "not null" if required
      modifiers << "references #{referenced_table.name}(#{referenced_table.id_field.name})"
      modifiers << "deferrable initially deferred" if deferrable

      @referenced_table = referenced_table
      super( context, name, nil, field_type, *modifiers)
   end

   attr_reader :referenced_table
   
end # ReferencedField
end # Generic
end # Adapters
end # Schemaform
