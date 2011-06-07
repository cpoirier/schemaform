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

require Schemaform.locate("tuple_class.rb")

#
# Base class for all Entity-backed Tuple materials. Entity-backed tuples keep track of things
# like IDs and keys, in order to provide additional features.

module Schemaform
module Materials
class EntityTuple < Tuple

   #
   # Defines a subclass into some container.

   def self.define( name, into )
      define_subclass( name, into ) do
         @@defaults = {}
         
         def self.default_for( name, tuple = nil )
            return nil unless @@defaults.member?(name)
            default = @@defaults[name]
            default.is_a?(Proc) ? default.call(tuple) : default
         end
         
         def self.load( name, entity_tuple )
            if entity = entity_tuple.instance_eval{@entity} then
               fail_todo "build EntityTuple::load() for entity-linked tuple"
            else
               default_for(name, entity_tuple)
            end
         end
      end
   end


   def initialize( attributes = {}, entity = nil )
      super( attributes )
      @entity = entity
   end
   

end # EntityTuple
end # Materials
end # Schemaform