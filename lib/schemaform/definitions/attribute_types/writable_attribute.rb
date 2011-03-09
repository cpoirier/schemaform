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

   def initialize( container, type = nil )
      super( container )
      @type = type
   end
   
   attr_accessor :type
   
   def recreate_in( tuple )
      self.class.new( tuple, @type ).tap do |recreation|
         recreation.name = name
      end
   end
   
   def writable?()
      true
   end
   
   def resolve( preferred = TypeInfo::SCALAR )
      supervisor.monitor(self) do
         @type.resolve(preferred).tap do |type|
            check do
               if type.scalar_type? then
                  assert( type.complete?, "scalar optional and required attributes must be of a complete type -- one that has both a Schemaform and a Ruby representation" )
               end
            end
         end
      end
   end
   

   # ==========================================================================================
   #                                           Conversion
   # ==========================================================================================

   
   def lay_out( builder )
      builder.define_attribute_default( name, resolve().default )
      super( builder )
   end

   
   
end # WritableAttribute
end # Definitions
end # Schemaform