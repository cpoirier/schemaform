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

require Schemaform.locate("field.rb")


#
# An auto-generated identifier field within a table.

module Schemaform
module Adapters
module Generic
class IdentifierField < Field

   def initialize( context, name, sf_type, field_type = "integer" )
      super( context, name, sf_type, field_type, "not null", "autoincrement" )
   end

end # IdentifierField
end # Generic
end # Adapters
end # Schemaform
