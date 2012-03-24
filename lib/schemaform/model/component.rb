#!/usr/bin/env ruby
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


#
# The base class for objects that make up the Schema.

module Schemaform
module Model
class Component
   include QualityAssurance
   extend QualityAssurance

   def initialize( name = nil, context = nil )
      type_check(:name, name, [Symbol, String], true)
      type_check(:context, context, Component, true)
      @schema  = Schema.current
      @context = context || @schema
      @name    = name
   end

   attr_reader :schema, :context, :name
   
   def each_context()
      result  = nil
      current = @context
      while current
         result  = yield(current)
         current = current.context
      end      
      result
   end
   
   def find_context( first = true, default = nil )
      match = default
      each_context do |current|
         if yield(current) then
            match = current
            break if first
         end
      end
      match
   end
   
   def acquire_for( new_owner )
      type_check("new_owner", new_owner, Component)
      self.context = new_owner
      self
   end
   
   def context=( new_context )
      @context = new_context
      @path = nil if defined?(@path)
   end
   
   def name=( name )
      @name = name
      @path = nil if defined?(@path)
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
   
   def verify()
      true
   end
   
   def description()
      name ? full_name : self.class.name
   end
   
   def to_s()
      description
   end
   
   def print_to( printer, name_override = nil )
      label = "#{self.class.unqualified_name} #{name_override || @name}"
      if block_given? then
         printer.label label do
            yield
         end
      else
         printer.print label
      end
   end
   
   
   #
   # Returns a version of the element in a new context. If you don't have a use for the 
   # changes, pass them through verbatim, for use by nested elements.
   
   def recreate_in( new_context, changes = nil )
      clone.acquire_for(new_context)
   end
   
   
   #
   # Returns the wrapper for this object in another module.
   
   def wrapper( target, *parameters )
      target.wrap(self, *parameters)
   end
   
   

end # Component
end # Model
end # Schemaform
