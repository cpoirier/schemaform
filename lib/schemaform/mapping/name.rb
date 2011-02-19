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
# Provides easily flattened "dotted" naming for Map objects.

module Schemaform
module Mapping
class Name

   def initialize( map, *components )
      @map        = map
      @components = components
   end
   
   def empty?()
      @components.empty?
   end
   
   def to_s()
      @map.map_name( @components )
   end
   
   def +( component )
      self.class.new( @map, @components + (component.is_a?(Name) ? component.components : [component]) )
   end

protected
   attr_reader :components

end # Name
end # Mapping
end # Schemaform