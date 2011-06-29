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


module Schemaform
class Schema
class TupleType < Type

   def initialize( tuple, attrs = {} )
      attrs[:context] = tuple.context unless attrs.member?(:context)
      super attrs
      @tuple = tuple
   end
   
   attr_reader :tuple
   
   def naming_type?
      true
   end
   
   def type()
      @tuple.type
   end
   
   def effective_type()
      @tuple.tuple.effective_type
   end
   
   def description()
      @tuple.description
   end
   
   def describe( indent = "", name_override = nil, suffix = nil )
      @tuple.describe(indent, name_override, suffix)
   end

   def attribute?( attribute_name )
      @tuple.attribute?(attribute_name)
   end
   

end # TupleType
end # Schema
end # Schemaform