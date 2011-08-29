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

require Schemaform.locate("relation.rb")
require Schemaform.locate("tuple.rb"   )


#
# A single entity within the schema.

module Schemaform
class Schema
class Entity < Relation
      
   def initialize( name, base_entity, schema )
      super(schema, name)
      @heading          = Tuple.new(self)
      @declared_heading = Tuple.new(self, nil, @heading.attributes)

      #
      # Import the base entity identifier attributes.

      @base_entity = base_entity
      @pedigree    = [self]

      if base_entity then
         @pedigree   = base_entity.pedigree + [self]
         @identifier = @heading.register(RequiredAttribute.new(:id, @heading, @base_entity.reference_type))  # @base_entity.reference_@base_entity.identifier)   # base_entity.identifier.recreate_in(@heading))
      else
         @identifier = @heading.register(IDAttribute.new(@heading, self))
      end
   end
   
   attr_reader :identifier, :declared_heading, :pedigree, :base_entity
   
   def type()
      @type ||= SetType.build(TupleType.new(@heading), :context => context)
   end
   
   def id()
      (@declared_heading.name.to_s.identifier_case + "_id").intern
   end

   def root_tuple()
      heading
   end
   
   def find( local_path )
      tuple      = @heading
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

   def identifier_type( context = nil )
      @identifier.type
   end
   
   def reference_type( context = nil )
      context = @context if context.nil?
      ReferenceType.new(@name, :context => context)
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
      @heading.describe(indent + "   ", @declared_heading.name)
   end
   
   
   #
   # Returns true if the named attribute is defined in this or any base entity.
   
   def attribute?( name )
      return @heading.attribute?(name)
   end
   

end # Entity
end # Schema
end # Schemaform


