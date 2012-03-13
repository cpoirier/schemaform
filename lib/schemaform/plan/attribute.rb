#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
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
# A wrapper on a Schema-defined Attribute that provides services to a runtime Tuple class. 

module Schemaform
module Plan
class Attribute
   
   ReadOnlyException       = Exception.define(:attribute)
   NotTupleValuedException = Exception.define(:attribute)

   def initialize( definition )
      @definition = definition
   end
   
   #
   # Returns the default value for this attribute.
   
   def default()
      fail_todo
   end
   
   #
   # Returns true IFF the symbol names a settable attribute of the Tuple.

   def settable?()
      @definition.writeable?
   end


   #
   # Validates a value for the named attribute.
   
   def validate( value )
      raise ReadOnlyException.new(self) unless settable?
      @definition.type.validate(value)
   end
   
   
   #
   # Returns true if the attribute is tuple-valued.
   
   def tuple_valued?()
      @definition.type.named_type?
   end


   #
   # Returns the Plan for any tuple-valued attribute. Returns nil otherwise.
   
   def tuple_plan()
      raise NotTupleValuedException.new(self) unless tuple_valued?
      @definition.type.tuple.plan
   end
   

end # Attribute
end # Plan
end # Schemaform