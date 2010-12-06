#!/usr/bin/env ruby -KU
# =============================================================================================
# SchemaForm
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
# Base class for all SchemaForm types.  Unlike Ruby, databases are (necessarily) rather strongly 
# typed, and the typing system provides a way to manage assignment and join compatibility,
# among other things.  

module SchemaForm
module Model
class Type

   def initialize()      
   end
   
   def simple_type?()
      return false
   end
   
   def tuple_type?()
      return false
   end
   
   def relation_type?
      return false
   end
   
   #
   # Returns or iterates over the last of types this type can effectively be.  Useful for 
   # isolating your code from some of the vagararies of type compatibility.
   
   def type_closure()
      if block_given? then
         yield self
      else
         return [self]
      end
   end
   
   def hash()
      self.class.name
   end
   
end # Type
end # Model
end # SchemaForm


Dir[$schemaform.local_path("types/*.rb")].each {|path| require path}

