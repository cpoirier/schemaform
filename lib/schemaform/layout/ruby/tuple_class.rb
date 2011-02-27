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


#
# Provides the runtime representation of a defined Tuple.

module Schemaform
module Layout
module Ruby
class TupleClass
   
   #
   # Defines a subclass and associates it with the Layout::Master.
   
   def self.define( name, master )
      define_subclass( name, master.schema_class ) do
         @@master = master
         def self.master()
            @@master
         end
      end
   end
   

   #
   # Defines an attribute reader for the specified name.
   
   def self.define_attribute_reader( name, &preamble )
      define_instance_method( name, preamble ) do
         instance_variable_get( "@#{name.to_s}" )
      end
   end
   
   #
   # Defines an attribute writer for the specified name
   
   def self.define_attribute_writer( name, &preamble )
      define_instance_method( "#{name.to_s}=", preamble ) do |value|
         @_dirty = true
         instance_variable_set( "@#{name.to_s}", value )
      end
   end



   def initialize()
      @_dirty = false
   end

end # TupleClass
end # Ruby
end # Layout
end # Schemaform