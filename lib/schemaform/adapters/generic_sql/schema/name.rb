#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
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


module Schemaform
module Adapters
module GenericSQL
class Name
   
   def initialize( components, separator )
      @separator  = separator
      @components = components.compact.collect{|name| name.is_a?(Name) ? name.components : name.to_s.identifier_case}.flatten
      @tail       = (@components.last == "?" ? @components.pop : "")
      @full_name  = @components.join(separator) + @tail
   end
   
   attr_reader :components
   
   def last()
      @components.last
   end
   
   def +( name )
      if name.is_a?(Name) then 
         self.class.new( @components + name.components, @separator )
      else
         self.class.new( @components + [name], @separator )
      end
   end
   
   def to_s()
      @full_name
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