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


module Schemaform
module Model
class IndirectType < Type

   def initialize( element, attrs = {} )
      super attrs
      @element = element
   end
   
   def acquire_for( new_context )
      @element.acquire_for(new_context)
      super
   end
   
   def to_element( context_collection = nil )
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
      super
   end
   

end # IndirectType
end # Model
end # Schemaform