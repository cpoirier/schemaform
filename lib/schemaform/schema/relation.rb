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

require Schemaform.locate("element.rb")


#
# Base class for named relations.

module Schemaform
class Schema
class Relation < Element

   def initialize( context, name )
      super(context, name)
            
      @keys        = Registry.new("#{full_name}", "a key"       )
      @operations  = Registry.new("#{full_name}", "an operation")
      @projections = Registry.new("#{full_name}", "a projection")
      @accessors   = Registry.new("#{full_name}", "an accessor" )
   end
   
   attr_reader :keys, :accessors, :operations, :projections

   def heading()
      type.member_type.tuple
   end
   
   def type()
      fail_unless_overridden self, :type
   end
   
   
   def project( *attributes )
      Relation.new(heading.project(*attributes), schema)
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
   
   
   
end # Relation
end # Schema
end # Schemaform


require Schemaform.locate("key.rb")

