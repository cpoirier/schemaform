#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2002 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================


#
# Assumes:
#    class Object
#       def instance_class()
#          class << self ; self ; end
#       end
#       
#       alias is_an? is_a?
#       alias responds_to? respond_to?
#    end


class Class
   
   #
   # Creates a subclass of this class, with the specified name and (optionally) definition. 
   
   def define_subclass( name, container = Object, &block )
      container.const_set( name, block ? Class.new(self, &block) : Class.new(self) )
   end
   
   
   #
   # Defines a new instance method, given one or more Procs.  Pass true after name if you want to
   # keep any existing method's functionality as part of the new function.
   #
   # BUG: There is probably a more efficient way to do this, and you should eventually go find it.
   
   def define_instance_method( name, *blocks, &block )
      blocks << block if block
      blocks.compact! if blocks.first.nil?

      #
      # Because this is a class-level function, the user's blocks don't have an object context, and 
      # we need to give them one.  In order to do this, we must convert the blocks to methods, so we 
      # can bind them to the object when called.  The same goes for any wrapper method we create.  
      # In order to avoid polluting the namespace, we just use the method name each time, replacing 
      # each existing method with the block version, and than with a wrapper method that calls them
      # both, by way of variables.  Note: because of this last bit (the use of variables to hold the
      # different versions, we can't eliminate the tail recursion, as we need a separate "copy" of
      # the variables for each wrapper.

      current_method = nil
      if blocks.first === true then
         blocks.shift
         begin; current_method = instance_method(name) ; rescue Exception ; end
      end

      send( :define_method, name, &(blocks.shift) )

      if current_method then
         block_method = instance_method( name )
         send( :define_method, name ) do |*args|
            current_method.bind(self).call(*args)
            block_method.bind(self).call(*args)
         end  
      end
      
      define_instance_method( name, true, *blocks ) unless blocks.empty?
   end

   
   #
   # Defines a new Class method, given one or more Procs.
   
   def define_class_method( name, *blocks, &block )
      instance_class.define_instance_method( name, *blocks, &block )
   end


end
