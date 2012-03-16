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
# An entity defined in terms of tuples and attributes and tuples, into which data can be written.

module Schemaform
module Model
class DefinedEntity < Entity
      
   def initialize( name, base_entity = nil )
      super(name)
      @heading     = Tuple.new()
      @structure   = Set.new(@heading, base_entity ? base_entity.structure : nil).acquire_for(self)
      @base_entity = base_entity
      @pedigree    = base_entity ? base_entity.pedigree + [self] : [self]
      
      @synonyms = []
      add_synonym(name)
   end
   
   def add_synonym( name )
      @synonyms << name
      @base_entity.add_synonym(name) if @base_entity
   end
   
   attr_reader :heading, :structure, :pedigree, :base_entity, :names
   
   def writable?()
      true
   end
   
   def type()
      unless @type
         @structure.add_typing_information(@synonyms) if @synonyms.length > 1
         @type = @structure.type
      end

      @type
   end
   
   def root_tuple()
      heading
   end
   
   def identifier_type()
      @identifier.type
   end
   
   def reference_type()
      EntityReferenceType.new(@name)
   end
   
   def primary_key()
      return @keys[@primary_key] unless @primary_key.nil?
      return @base_entity.primary_key unless @base_entity.nil?
      return nil
   end
   
   def register_tuple( tuple )
      schema.register_tuple(tuple)
   end
   
   def print_to( printer )
      type()
      super do
         @structure.print_to(printer)
      end
   end

end # DefinedEntity
end # Model
end # Schemaform


