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

require Schemaform.locate("scalar_type.rb")


#
# Base class for numeric types. Handles the :range modifier to limit value.

module Schemaform
class Schema
class NumericType < ScalarType

   def initialize( attrs )
      if attrs.member?(:range) then
         @range = attrs.delete(:range)
         attrs[:default] = (@range.member?(0) ? 0 : @range.start) unless attrs.member?(:default)
      else
         attrs[:default] = 0 unless attrs.member?(:default)
      end

      super
   end
   
   def make_specific( modifiers )
      if !@range && modifiers.fetch(:range, nil).is_a?(Range) then
         self.class.new(:base_type => self, :range => modifiers.delete(:range))
      else
         super
      end
   end
   
end # NumericType
end # Schema
end # Schemaform