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
   # Returns a specialized Symbol version of the supplied name, base on this object's class name.
   #
   # Example:
   #    <object:SomeClass>.specialize("process") => :process_some_class
   
   def specialize_method_name( name )
      return "#{name}#{(is_a?(Class) ? self : self.class).name.split("::")[-1].gsub(/[A-Z]/){|s| "_#{s.downcase}"}}".intern
   end
   
   
   #
   # Sends a specialized method to this object.  Will follow the class hierarchy for the
   # determinant object, searching for a specialization this object supports.  Failing that, 
   # the default_specialization will be used, if supplied.

   def send_specialized( name, default_specialization, determinant, *parameters )
      current_class = determinant.is_a?(Class) ? determinant : determinant.class
      while current_class
         specialized = current_class.specialize_method_name(name)
         return self.send( specialized, determinant, *parameters ) if self.responds_to?(specialized)
         current_class = current_class.superclass
      end
         
      specialized = name + (default_specialization ? "_" + default_specialization : "")
      return self.send( specialized, determinant, *parameters )
   end
   
   
   #
   # Returns this object in an array.
   
   def to_a()
      return [self]
   end
end


