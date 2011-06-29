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


require Schemaform.locate("writable_attribute.rb")


#
# A required attribute -- one that must be present within its context TupleType.

module Schemaform
class Schema
class RequiredAttribute < WritableAttribute

protected

   extend QualityAssurance
   warn_once( "TODO: build the constructor for the TupleClass" )
   warn_once( "TODO: build a general runtime Tuple class that can wrap a hash" )
   

end # RequiredAttribute
end # Schema
end # Schemaform