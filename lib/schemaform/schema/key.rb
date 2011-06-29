#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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


module Schemaform
class Schema
class Key < Element
      
   def initialize( attribute_names, context )
      # warn_once "Key should probably be changed to use a backed StructuredType instead of a Tuple"
      # 
      # @attributes = Tuple.new()
      # attribute_names.each do |name|
      #    @attributes.add_attribute( name, entity.heading.attributes[name] )
      # end
      # # @attributes = attribute_names
   end
   # 
   # alias entity context
   # 
   # def each_attribute( &block )
   #    @attributes.each_attribute( &block )
   # end
   # 
   # def member?( name )
   #    @attributes.member?(name)
   # end
   # 
   # def type()
   #    supervisor.monitor(self) do
   #       @attributes.type()
   #    end
   # end
   # 
   # def description()
   #    @attributes.description
   # end
   
end # Key
end # Schema
end # Schemaform

