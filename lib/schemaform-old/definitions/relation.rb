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

require Schemaform.locate("type.rb")

#
# A base class for all Relations within Schemaform (Entities, Subsets, etc.)

module Schemaform
module Definitions
class Relation < Type

   def initialize( context, heading, name = nil )
      super( context, name )
      @heading = heading
   end
   
   attr_reader :heading

   def type_info()
      return TypeInfo::RELATION
   end
   
   def description()
      "[" + @heading.description + "]"
   end
   
   def resolve( relation_types_as = :reference )
      supervisor.monitor(self) do
         @heading.resolve()
         self
      end
   end
   
   def each_attribute( &block )
      @heading.each_attribute( &block )
   end
   

end # Relation
end # Definitions
end # Schemaform