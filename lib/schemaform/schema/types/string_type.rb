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

require Schemaform.locate("scalar_type.rb")


#
# The base class for types that implement a string of data (text and binary).

module Schemaform
class Schema
class StringType < ScalarType

   def initialize( attrs )
      @length = attrs.delete(:length)      
      super attrs
   end
   
   attr_reader :length
   
   #
   # For the undimensioned type, handles dimensioning.
   
   def make_specific( modifiers )
      if !@length && modifiers.fetch(:length, 0) > 0 then
         self.class.new(:base_type => self, :length => modifiers.delete(:length))
      else
         super
      end
   end
   
   def description()
      (@length.exists? && @length > 0) ? (super + "[#{@length}]") : super
   end
   

end # StringType
end # Schema
end # Schemaform