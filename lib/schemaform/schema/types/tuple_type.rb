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
# A dimension 1 type, in which there is a set of name/type pairs (the attributes).

module Schemaform
class Schema
module Types
class TupleType < Type
   
   def initialize( schema, attributes = {}, closed = false )
      super( schema )
      @attributes = attributes 
      @closed     = closed
   end
   
   def dimensionality() 
      1
   end

   #
   # Adds an attribute to the tuple.

   def add( name, type )
      check do
         type_check("name", name, Symbol)
         type_check("type", type, Type  )
         assert( !@closed, "tuple type must not be closed to new attributes" )
         assert( !@attributes.member?(name), "tuple type cannot have two attributes with the same name (#{name})" )
      end
          
      @attributes[name] = type
   end
   
   #
   # Closes the type to further changes.
   
   def close()
      @closed = true
   end
   

end # TupleType
end # Types
end # Schema
end # Schemaform

