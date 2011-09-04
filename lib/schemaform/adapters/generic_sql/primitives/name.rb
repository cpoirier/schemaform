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
module Adapters
module GenericSQL
class Name
   
   def self.build( *components )
      return components.first if components.length == 1 && components.first.is_a?(Name)
      new(components)
   end
   
   def self.empty()
      @@empty ||= new([])
   end

   def initialize( components )
      @components = components.compact.collect{|name| name.is_a?(Name) ? name.components : name.to_s.identifier_case}.flatten
      @full_name  = @components.join("$")
   end
   
   attr_reader :components
   
   def last()
      @components.last
   end
   
   def +( name )
      if name.is_a?(Name) then 
         self.class.new( @components + name.components )
      else
         self.class.new( @components + [name] )
      end
   end
   
   def to_s( separator = "$" )
      separator == "$" ? @full_name : @components.join(separator)
   end

   def hash()
      to_s.hash()
   end
   
   def ==( rhs )
      to_s == rhs.to_s
   end
   
   
end # Name
end # GenericSQL
end # Adapters
end # Schemaform