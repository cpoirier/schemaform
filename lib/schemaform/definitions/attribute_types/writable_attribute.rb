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
# An original (as opposed to derived) attribute.

module Schemaform
module Definitions
class WritableAttribute < Attribute

   def initialize( container, definition )
      super(container)
      @definition = definition
   end
   
   
   def recreate_in( tuple )
      self.class.new( tuple, @definition ).tap do |recreation|
         recreation.name = name
      end
   end
   
   def writable?()
      true
   end
   
   def type()
      @definition.type
   end

   

   # ==========================================================================================
   #                                           Conversion
   # ==========================================================================================

   
   
   def lay_out( into )
      super(into).tap do |group|
         send_specialized(:lay_out, @definition, group)
      end
   end
   

   
   
end # WritableAttribute
end # Definitions
end # Schemaform