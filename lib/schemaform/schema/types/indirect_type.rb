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
class IndirectType < Type

   def initialize( element, attrs = {} )
      attrs[:context] = element.context unless attrs.member?(:context)
      super attrs
      @element = element
   end
   
   def to_element()
      @element
   end
   
   attr_reader :element
   
   def naming_type?
      @element.has_attributes?
   end
   
   def attribute?( attribute_name )
      @element.attribute?(attribute_name)
   end
   
   def type()
      @element.type
   end
   
   def effective_type()
      fail "is the old code a bug?"
      @tuple.tuple.effective_type
   end
   
   def description()
      @element.description
   end
   
   def print_to( printer )
      @element.print_to(printer)
   end

   def verify()
      @element.verify()
   end
   

end # IndirectType
end # Schema
end # Schemaform