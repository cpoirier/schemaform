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
# Base class for relation types.

module Schemaform
module Definitions
class RelationType < Type
   
   #
   # The heading is a required part of the RelationType, and must be a StructuredType.
   
   def initialize( heading, attrs )
      super attrs
      @heading = heading
   end
   
   def relation_type?()
      true
   end
   
   def description()
      "[" + @heading.description + "]"
   end

   def each_attribute( &block )
      @heading.each_attribute( &block )
   end


end # RelationType
end # Definitions
end # Schemaform


