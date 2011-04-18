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
# Base class for 

module Schemaform
module Expressions
module Attributes
class MultivaluedAttribute < Attribute

   def initialize( definition )
      super( definition )
   end
   

end # MultivaluedAttribute < Attribute
end # Attributes
end # Expressions
end # Schemaform

tuple.set_field.each -- that's it
tuple.sequence_field.first, .last -- that's it  --- first and last return Singular wrapper?
tuple.relation_field.each + tuple.relation_field.attribute -- Plural wrapper?
tuple.enumeration_field.each + tuple.enumeration_field.attribute -- Plural wrapper + next & previous

RelationAttribute
   .each -> Tuple
   .attribute -> 

set -- no fields
sequence -- no fields
relation -- fields
enumeration -- fields
