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
# A tuple, potentially linked to an entity record (if identifiable).

module Schemaform
module Model
module Expressions
class TupleExpression

   def initialize( type, source = nil )
      super( type )
      @source = source      
   end
   
   #
   # Returns the Schemaform record identifier expression for this tuple, if known.
   
   def id()
      assert( @source.exists?, "source record not identifiable in this context" )
      fail( "TODO: generate ID expression" )
   end
   
   
   #
   # Returns a subset of some relation for which the first (or specified) reference
   # field refers to this tuple (if identifiable).

   def find_matching( relation, on_field = nil )
      assert( @source.exists?, "source record not identifiable in this context" )
      relation = RelationExpression.new( @schema.relation(relation) )
      relation 
      if
         
         
   end
   
   
   #
   # Returns a FieldExpression for any of this tuple's fields.
   
   def method_missing(  )
      if @type.member?()
   end
   
   
   

end # TupleExpression
end # Expressions
end # Model
end # Schemaform