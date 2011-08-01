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
# Base class for capturing a mapping from a tuple attribute.

module Schemaform
module Adapters
module Generic
class TupleAttributeMapping < AttributeMapping

   def initialize( attribute, attribute_mappings = {} )
      super(attribute)
      @attribute_mappings = attribute_mappings
   end
   
   attr_reader :attribute_mappings

end # TupleAttributeMapping


#
# Add a helper routine to Table.

class Table
   def map_tuple_attribute( attribute, attribute_mappings )
      @schema.map_attribute attribute, TupleAttributeMapping.new(attribute, attribute_mappings)
   end
end
   

end # Generic
end # Adapters
end # Schemaform