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



#
# The SF equivalent of an array type -- but one that does not support duplicates, in keeping with
# the zeitgeist of set math.  If you need a non-unique set (ie. an actual array), you'll need to
# make an entity with an index attribute.

module Schemaform
module Definitions
class SetType < Type

   #
   # If you specify a Schema, it will be used.  If not, it will be pulled from the base Type.
   
   def initialize( member_type = nil, schema = nil, name = nil )
      super( schema || member_type.schema, name )
      @member_type = member_type
   end
   
   attr_reader :member_type
   
   def type_info()
      TypeInfo::SET  
   end
   
   def description()
      # return name.to_s if named?
      return "[#{@member_type.resolve.description}]"
   end

   def resolve()
      @member_type.resolve()
      self
   end
   

end # SetType
end # Definitions
end # Schemaform

