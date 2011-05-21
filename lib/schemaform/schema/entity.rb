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

require Schemaform.locate("relation.rb")
require Schemaform.locate("tuple.rb"   )


#
# A single entity within the schema.

module Schemaform
class Schema
class Entity < Relation
      
   def initialize( name, base_entity, schema )
      super(Tuple.new(self), schema, name)
      @identifiers      = Tuple.new(self, :identifiers, heading.attributes)
      @declared_heading = Tuple.new(self, nil         , heading.attributes)

      #
      # Import the base entity identifier attributes.

      @base_entity = base_entity
      @pedigree    = [self]

      if base_entity then
         @pedigree = base_entity.pedigree + [self]
         base_entity.identifiers.each do |id| 
            @identifiers.register(id.recreate_in(@identifiers))
         end
      end

      @identifiers.register(IDAttribute.new(@identifiers))

      #
      # Other stuff.
      
      @keys = {}
   end
   
   attr_reader :keys, :identifiers, :declared_heading, :pedigree
   
   def id()
      (@declared_heading.name.to_s.identifier_case + "_id").intern
   end
   
   def has_base_entity?()
      @base_entity.exists?
   end
   
   def description()
      full_name() + " " + super
   end
   
   def primary_key()
      return @keys[@primary_key] unless @primary_key.nil?
      return @base_entity.primary_key unless @base_entity.nil?
      return nil
   end
   
   def register_tuple( tuple )
      schema.register_tuple(tuple)
   end
   
   def describe( indent = "", name_override = nil, suffix = nil )
      super
      @heading.describe(indent + "   ")
   end
   
   
   #
   # Returns true if the named attribute is defined in this or any base entity.
   
   def attribute?( name )
      return @heading.attribute?(name)
   end
   
   #
   # Returns true if the named key is defined in this or any base entity.
   
   def key?( name )
      return true if @keys.member?(name)
      return @base_entity.key?(name) if @base_entity.exists?
      return false
   end

   
   #
   # If true, this entity is enumerated.
   
   def enumerated?()
      @enumeration.exists?
   end
   

   

end # Entity
end # Schema
end # Schemaform


require Schemaform.locate("key.rb")

