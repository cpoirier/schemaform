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
   def instance_class()
      class << self ; self ; end
   end
   
   alias is_an? is_a?
   alias responds_to? respond_to?

   def each()
      yield( self ) 
   end
   
   def exists?()
      return true
   end
   
   alias set? exists?
   
   #
   # Sets the named instance variable to a value, and enters the supplied block, passing
   # this object.  Restores the instance variable to its original value before returning.
   # Do not include the @ in the variable name.
   
   def with_value( name, value, &block )
      result   = nil
      
      name     = "@#{name.to_s}"
      previous = instance_variable_get( name )
      begin
         instance_variable_set( name, value )
         result = block.call( self )
      ensure
         instance_variable_set( name, previous )
      end
      
      result
   end
   
   
   #
   # Equivalent to with_value(), but accepts multiple name/value pairs.
   
   def with_values( pairs = {}, &block )
      result   = nil
      previous = {}
      begin
         pairs.each do |name, value|
            variable = "@#{name.to_s}"
            previous[name] = instance_variable_get( variable )
            instance_variable_set( variable, value )
         end

         result = yield( self )
      ensure
         previous.each do |name, value|
            instance_variable_set( "@#{name.to_s}", value )
         end
      end
      
      result
   end
   
   
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


