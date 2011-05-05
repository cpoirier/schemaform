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

require Schemaform.locate("../type.rb")


#
# Base class for container types.

module Schemaform
module Definitions
class CollectionType < Type

   attr_reader :element_type

   def initialize( element_type, attrs = {} )
      @element_type = element_type
      attrs[:context] = element_type.context unless attrs.member?(:context) || attrs.member?(:base_type)
      super(attrs)
   end

end # CollectionType
end # Definitions
end # Schemaform