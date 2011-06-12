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


module Schemaform
class Schema
class StructuredType < Type
   
   #
   # Additional attributes:
   #  :members => an initial set of name => Type pairs
   #  :lookup  => a Proc to use to handle lookups, for backed types
   #
   # Note: your lookup routine will only ever be called for already-registered names that have
   # no type value. Any type you return will be stored for future use, thereby bypassing future
   # calls to your routine.
   
   def initialize( attrs, &lookup )
      super
      @members = {}
      @lookup  = lookup || attrs.fetch(:lookup, nil)
      
      if initial_members = attrs.fetch(:members, nil) then
         initial_members.each do |name, type|
            register( name, type )
         end
      end
   end
   
   def naming_type?
      true
   end
   
   def simple_type?
      @members.length == 1
   end
   
   def description()
      # Bad for lazy resolution: "{" + @members.collect{|name, type| ":" + name.to_s + " => " + type.description}.join(", ") + "}"
      "{" + names.join(", ") + "}"
   end
   
   def names()
      @members.keys + (@lookup ? @lookup.call(nil) : [])
   end
   
   def member?( name )
      @members.member?(name) || (@lookup && @lookup.call(name))
   end
   
   def register( name, type = nil )
      check do 
         type_check(:name, name, Symbol)
         assert(!@members.member?(name), "[#{full_name}] already has a member named [#{name}]")
      end
      
      @members[name] = type
   end
   
   def []=( name, value )
      assert(@members.member?(name), "[#{full_name}] does not have a member named [#{name}]; please register() it first")
      @members[name] = value
   end
   
   def []( name )
      assert(@members.member?(name), "[#{full_name}] does not have a member named [#{name}]")
      @members[name] = @lookup.call(name) if @members[name].nil? && @lookup
      @members[name]
   end
   

end # StructuredType
end # Schema
end # Schemaform
