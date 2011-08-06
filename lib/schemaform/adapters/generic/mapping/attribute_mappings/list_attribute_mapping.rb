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
# Captures a mapping from a list attribute.

module Schemaform
module Adapters
module Generic
class ListAttributeMapping < AttributeMapping

   def initialize( attribute, member_mapping, member_previous, member_next, list_first, list_last )
      super(attribute)
      @member_mapping  = member_mapping
      @member_previous = member_previous
      @member_next     = member_next
      @list_first      = list_first
      @list_last       = list_last
   end

end # ListAttributeMapping



#
# Add a helper routine to Table.

class Table
   def map_list_attribute( attribute, member_mapping, member_previous, member_next, list_first, list_last )
      @schema.map_attribute attribute, ListAttributeMapping.new(attribute, member_mapping, member_previous, member_next, list_first, list_last)
   end
end
   
end # Generic
end # Adapters
end # Schemaform
