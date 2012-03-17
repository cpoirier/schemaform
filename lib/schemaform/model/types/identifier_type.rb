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

#
# Similar to a ReferenceType, except that the IdentifierType creates the thing that can be
# referenced.

module Schemaform
module Model
class IdentifierType < Type

   def initialize( collection, attrs = {} )
      super attrs
      @collection = collection
      @base_type  = ReferenceType.new(collection)
   end
   
   attr_reader :collection
   
   def naming_type?
      fail_todo "why is this called?"
   end
   
   def referenced_collection()
      @collection
   end
   
   def description()
      "#{@collection.full_name} identifier"
   end
   
   

end # IdentifierType
end # Model
end # Schemaform