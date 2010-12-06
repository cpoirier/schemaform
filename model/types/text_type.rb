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
# The SchemaForm text type.  Generally maps to String in Ruby and either varchar or text in 
# the database.

module SchemaForm
module Model
module Types
class TextType < Type

   attr_reader :length
   
   def initialize( maximum_characters )
      @length = maximum_characters
   end
   
   def simple_type?()
      return true
   end
   
   def type_closure()
      if block_given? then
         yield self
         yield @@unbounded
      else
         return [self, @@unbounded]
      end
   end
   
   def to_s()
      return @length > 0 ? "text_type(#{@length})" : "text_type()"
   end
   
   def hash()
      "TextType:#{@length}".hash
   end
   
   def eql?( rhs )
      rhs.is_a?(TextType) && rhs.length == @length
   end
   
   @@unbounded = self.new(0)

end # TextType < Type
end # Types
end # Model
end # SchemaForm