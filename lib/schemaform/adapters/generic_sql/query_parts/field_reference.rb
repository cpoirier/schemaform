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

require Schemaform.locate("field.rb")


#
# Base class for things that help make up a Query.

module Schemaform
module Adapters
module GenericSQL
module QueryParts
class FieldReference < Field

   def initialize( type_info, source, field_name )
      super(type_info)
      @source     = source
      @field_name = field_name.to_s
   end

   attr_reader :source
   attr_reader :field_name
   
   def print_to( printer )
      printer << adapter().quote_identifier("#{source.alias}.#{@field_name}")
   end
   

end # FieldReference
end # QueryParts
end # GenericSQL
end # Adapters
end # Schemaform