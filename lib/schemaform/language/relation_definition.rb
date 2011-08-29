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


#
# comment

module Schemaform
module Language
class RelationDefinition
   include QualityAssurance 
      
   def self.process( relation, &block )
      dsl = new(relation)
      dsl.instance_eval(&block)
      relation
   end

   
   def initialize( relation )
      @relation = relation
      @schema   = relation.schema
   end

   #
   # Defines a candidate key on the relation -- a subset of attributes that can uniquely identify
   # a record within the set. 
   #
   # There are several ways to call it:
   #    key *symbols
   #    key name, :on => array of symbols
   #    key name, :on => lambda expression that results in an array of attributes
   #    key name, :on => nil do |tuple|
   #       [tuple.x, tuple.y, ...]
   #    end
   #
   # Keys can support a :where clause, which is used to limit the scope of the uniqueness. These
   # "partial" keys are particuarly useful for optional attributes, where you might only want 
   # present values to be unique. The value of the :where clause should be a lambda expression that
   # takes the entity tuple as sole parameter. Note that you can only supply nil for one or the other
   # of :on or :where, if you want to use the block form. 
   
   def key( *args, &block )
      args = [args.collect{|symbol| symbol.to_s}.join("_and_"), {:on => args}] unless args.last.is_a?(Hash)
      
      name, hash = *args
      attributes = hash.fetch(:on) || block
      if hash.member?(:where) then
         where = hash.fetch(:where) || block
         fail_todo
      else
         key = Schema::Key.new(@relation, name, lambda{|relation| relation.project_attributes(attributes)})
         @relation.keys.register key
         @relation.accessors.register Schema::KeyAccessor.new(key)
      end
   end
   
   
   #
   # Defines a projection of attributes that can be used to limit the data transferred back 
   # when tuples are retrieved.
   #
   # There are several ways to call it:
   #    projection name, :project => array of symbols
   #    projection name, :project => lambda expression that results in an array of attributes
   #    projection name, :project => nil do |tuple|
   #       [tuple.x, tuple.y, ...]
   #    end
   
   def projection( name, details, &block )
      attributes = details.fetch(:project) || block
      @relation.projections.register Schema::Projection.new(@relation, name, lambda{|relation| relation.project_attributes(attributes)})
   end
   
   
   #
   # Defines an accessor on the entity. Projections will automatically be applied to your accessors, so 
   # always project out the full entity.
   #
   # There are several ways to call it:
   #    accessor *symbols
   #    accessor name, :on => array of symbols
   #    accessor name, :where => complete query on the entity that specifies the tuples to return
   #    accessor name, :where => nil do |tuple|
   #       tuple.x == parameter(0) & tuple.y == parameter(1)
   #    end
      
   def accessor( *args, &block )
      args = [args.collect{|symbol| symbol.to_s}.join("_and_"), {:on => args}] unless args.last.is_a?(Hash)
      
      name, hash = *args
      if hash.member?(:on) then
         attributes = hash[:on]
         @relation.accessors.register Schema::GeneratedAccessor.new(@relation, name, lambda{|relation| relation.project_attributes(attributes)} )
      elsif hash.member?(:where) then
         @relation.accessors.register Schema::DefinedAccessor.new(@relation, name, hash.fetch(:where) || block)
      else
         fail
      end
   end
   
   
   #
   # Defines an operation on the entity. Operations are free-form methods added to the
   # Entity class internally.
   
   def operation( name, &block )
      @entity.operations.register(block, name)
   end
   

end # RelationDefinition
end # Language
end # Schemaform
