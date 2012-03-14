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


#
# Provides named-object management service to the system.

module Schemaform
class Registry
   include QualityAssurance
   include Enumerable
   
   def initialize( owner_description = "the registry", member_description = "an object", chain = nil, &name_cleaner )
      @registry           = {}
      @order              = []
      @chain              = chain
      @owner_description  = owner_description
      @member_description = member_description
      @name_cleaner       = name_cleaner
   end
   
   def empty?()
      @registry.empty?
   end
   
   def chain=( registry )
      assert(@chain.nil?, "[#{@owner_description.to_s}] already has a chained registry")
      @chain = registry
   end
   
   def count()
      @order.count
   end
   

   #
   # Checks if the named object exists.
   
   def member?( name )
      @registry.member?(name)
   end
   
   
   #
   # Returns the named object, or nil.
   
   def []( name )
      find(name, false)
   end
   
   
   #
   # Returns the named object or your default.
   
   def fetch( name, value = nil )
      @registry.fetch(name, value)
   end
   
   
   #
   # Iterates of the registered objects. Passes only the object (not the name).
   
   def each( &block )
      if block.arity == 2 then
         @order.each do |name|
            yield(name, @registry[name])
         end
      else
         @order.each do |name|
            yield(@registry[name])
         end
      end
   end
   
   
   #
   # Returns the names of all registered objects.
   
   def names()
      @order
   end
   
   
   #
   # Returns all registered objects, in registration order.
   
   def members()
      @order.collect{|name| @registry[name]}
   end

   
   #
   # Registers a named object with the schema.
   
   def register( definition, name = nil )
      name = definition.name unless name
      name = @name_cleaner.call(name) if @name_cleaner
      assert( name, "unable to find a name to use", :definition => definition )
      
      unless @registry.member?(name) && @registry[name].object_id == definition.object_id then
         check{ assert(!@registry.member?(name), "[#{@owner_description.to_s}] already has [#{@member_description.to_s}] named [#{name}]", :registered => @order.join(", ") ) }         
         @registry[name] = definition
         @order << name
         @chain.register(definition, name) if @chain
      end
      
      definition
   end
   
   
   #
   # Finds the specified object and renames it. Note that the element itself will be renamed 
   # if it supports name=()
   
   def rename( from, to )
      check do
         assert(@registry.member?(from), "[#{@owner_descrpition.to_s}] cannot rename [#{from}], as the name is not in use")
         assert(!@registry.member?(to) , "[#{@owner_descrpition.to_s}] cannot rename [#{from}] to [#{to}], as the name is already in use")
      end
      
      if object = @registry.delete(from) then
         object.name = to if object.responds_to?(:name=)
         @registry[to] = object
         @order[@order.index(from)] = to
         @chain.rename(from, to) if @chain
      end
   end
   
   
   #
   # Returns the named object.
   
   def find( name, fail_if_missing = true )
      # return name unless name.is_a?(Symbol) || name.is_a?(String)
      name = @name_cleaner.call(name) if @name_cleaner
      
      definition = nil
      current    = name
      while current && definition.nil?
         definition = @registry[current] if @registry.member?(current)
         current    = current.is_a?(Class) ? current.superclass : nil
      end

      return definition if definition
      return nil unless fail_if_missing
      fail("unrecognized [#{name}]")
   end


   #
   # Creates a copy of this registry, possibly with renamed members (if you supply a block).
   
   def dup()
      Registry.new().use do |copy|
         each do |name, value|
            name = yield(name, value) if block_given?
            copy.register(value, name)
         end
      end
   end


end # Registry
end # Schemaform
