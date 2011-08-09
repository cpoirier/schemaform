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
# Captures informtion about how a Schema::Attribute is mapped into Fields.

module Schemaform
module Adapters
module Generic
class AttributeMapping

   def initialize( attribute )
      @attribute = attribute
   end
   
   attr_accessor :optional_marker 

end # AttributeMapping


#
# Add helper routines to Table.

class Table
   def map_optional_marker( attribute, field )
      attribute_mappings[attribute].optional_marker = field
   end
end
   

end # Generic
end # Adapters
end # Schemaform

Dir[Schemaform.locate("attribute_mappings/*.rb")].each{|path| require path}