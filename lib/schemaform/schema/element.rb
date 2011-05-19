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
# The base class for objects that make up the Schema.

module Schemaform
class Schema
class Element
   include QualityAssurance
   extend QualityAssurance

   def initialize( context, name = nil )
      @context = context
      @name    = name
      
      type_check(:context, @context, [Element, Schema])
   end
   
   def context()
      assert( @context, "Element is missing a context; either you did not initialize the Element, or you called an Element method before initialization is complete")
      @context
   end
   
   def context=( new_context )
      @context = new_context
      @path = nil if defined?(@path)
   end
   
   def schema()
      assert( @context, "Element is missing a context; either you did not initialize the Element, or you called an Element method before initialization is complete")
      @context.schema
   end
   
   def name=( name )
      @name = name
      @path = nil if defined?(@path)
   end

   def name()
      @name
   end
   
   def path()
      if @path.nil? then
         @path = []
         
         if name = name() then
            @path += [name]
         end
         
         if context.responds_to?(:path) then
            @path = context.path + @path
         elsif context.responds_to?(:name) and context.name then
            @path = [context.name] + @path
         end
      end
      
      @path
   end
   
   def full_name()
      path.collect{|n| n.to_s}.join(".")
   end
   
   def description()
      name ? full_name : self.class.name
   end
   
   def to_s()
      description
   end
   
   def describe( indent = "", name_override = nil, suffix = nil )
      puts "#{indent}#{self.class.name.split("::").last}: #{name_override || @name}#{suffix ? " " + suffix : ""}"
   end
   
   
   #
   # Returns a version of the element in a new context. If you don't have a use for the 
   # changes, pass them through verbatim, for use by nested elements.
   
   def recreate_in( new_context, changes = nil )
      clone.tap do |element|
         element.instance_eval do
            @context = new_context
            @path    = nil
         end
      end
   end
   
   
   

end # Element
end # Schema
end # Schemaform