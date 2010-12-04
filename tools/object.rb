#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2007-2008 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================


class Object
   def each()
      yield( self ) 
   end
   
   def exists?()
      return true
   end
   
   alias set? exists?
   
   alias is_an? is_a?
   alias responds_to? respond_to?

   
   #
   # specialize_method_name( name )
   #  - returns a specialized Symbol version of the supplied name, based on this object's class name
   #  - example: <object:SomeClass>.specialize("process") => :process_some_class
   
   def specialize_method_name( name )
      return "#{name}#{(is_a?(Class) ? self : self.class).name.split("::")[-1].gsub(/[A-Z]/){|s| "_#{s.downcase}"}}".intern
   end
   
   def send_specialized( name, default_specialization, determinant, *parameters )
      specialized = determinant.specialize_method_name(name)
      specialized = name + (default_specialization ? "_" + default_specialization : "") if !self.responds_to?(specialized)
      
      return self.send( specialized, determinant, *parameters )
   end
   
   
   def as( klass, default = nil )
      return self if self.is_a?(klass)
      
      specialized = klass.specialize_method_name( "as" )
      if self.responds_to?(specialized) then
         return self.send( specialized )
      else
         return default
      end
   end

   def as_array()
      return [self]
   end

   def to_a()
      return [self]
   end
end


