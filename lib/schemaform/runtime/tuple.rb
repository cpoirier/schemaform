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
# Represents a (possibly database-backed) tuple in memory. Provides access to attributes and 
# tuple operations. In order to keep things consistent across the system, if you want to use
# the attributes by accessor (instead of by the [] operator), attribute names that conflict 
# with a method must be accessed with a ! (ie. if you have an attribute named 
# :object_id, which conflicts with the method on Object, you must access it a tuple.object_id!
# or tuple[:object_id]).

module Schemaform
module Runtime
class Tuple

   def initialize( attributes, plan = nil )
      @plan       = plan
      @attributes = plan ? {} : attributes.dup
      @unsaved    = true

      if @plan then
         attributes.each do |name, value|
            self[name] = value
         end
      end
   end

   def []( name )
      return @attributes[name] if @attributes.member?(name)
      @plan[name].default
   end
   
   def []=( name, value )
      @unsaved = true
      
      if value.exists? then
         case value
         when Hash
            value = Tuple.new(value, @plan ? @plan[name].tuple_plan : nil)
         when Array
            fail_todo
         when Set
            fail_todo
         end
            
         @attributes[name] = @plan ? @plan[name].validate(value) : value
      else
         @attributes.delete(name)
      end
   end
   
   def method_missing( symbol, *args, &block )
      name = symbol.to_s

      if name.ends_with?("=") then
         return super unless args.length == 1 && block.nil?
         self[name.slice(0..-2).intern] = args.first
      elsif name.ends_with?("?") then
         return super
      else
         return super unless args.empty? && block.nil?
         name.slice!(-1..-1) if name.ends_with?("!") 
         self[name.intern]
      end
   end
   
   def unsaved?()
      @unsaved
   end
   

end # Tuple
end # Runtime
end # Schemaform
