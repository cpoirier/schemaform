#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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

require Schemaform.locate("component.rb")


#
# Base class for named entities (which are either defined or derived).

module Schemaform
class Schema
class Entity < Component

   def initialize( name )
      super(name)
            
      @keys        = Registry.new("#{full_name}", "a key"       )
      @operations  = Registry.new("#{full_name}", "an operation")
      @projections = Registry.new("#{full_name}", "a projection"){|name| name.to_s}
      @accessors   = Registry.new("#{full_name}", "an accessor" ){|name| name.to_s}
   end
   
   attr_reader :keys, :accessors, :operations, :projections

   def structure()
      fail_unless_overridden
   end

   def base_entity()
      nil
   end
   
   def id()
      fail_obsolete "Entities no longer have IDs; tuples are now identified via their membership in a collection"
   end
   
   def identifier()
      fail_obsolete "Entities no longer have IDs; tuples are now identified via their membership in a collection"
   end
   
   def heading()
      type.member_type.tuple
   end
   
   def type()
      fail_unless_overridden
   end
   
   def verify()
      assert(type.verify()     , "unable to verify type for #{full_name}"     )
      assert(structure.exists? , "unable to build structure for #{full_name}" )
      assert(structure.verify(), "unable to verify structure for #{full_name}")
   end
   
   def description()
      full_name() + " " + super
   end
   
   def writable?()
      false
   end
   
   #
   # Returns true if the named key is defined in this or any base entity.
   
   def key?( name )
      return true if @keys.member?(name)
      return @base_entity.key?(name) if @base_entity.exists?
      return false
   end

   
   #
   # Returns true if the named projection is defined in this or any base entity.
   
   def projection?( name )
      return true if @projections.member?(name)
      return @base_entity.projection?(name) if @base_entity.exists?
      return false
   end

   
   #
   # Returns true if the named attribute is defined in this or any base entity.
   
   def attribute?( name )
      return heading.attribute?(name)
   end
   
   
   #
   # Finds an attribute within the Entity by name path.
   
   def find( local_path )
      tuple      = heading
      attribute  = nil
      
      while attribute.nil? && (name = local_path.shift)
         if attribute = tuple.attributes[name] then
            if attribute.type.is_a?(TupleType) then
               tuple = attribute.type.tuple
               attribute = nil
            end
         end
      end
      
      attribute
   end

   
   
end # Entity
end # Schema
end # Schemaform


Dir[Schemaform.locate("entity_types/*.rb")].each {|path| require path}

