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

require 'monitor'


#
# Provides a naming context and a unit of storage within the Schemaform system.

module Schemaform
module Definitions
class Schema < Definition
   
   @@schemas = {}
   @@monitor = Monitor.new()

   def self.[]( name )
      @@monitor.synchronize { @@schemas[name] }
   end
   
   def self.defined?( name )
      @@monitor.synchronize { @@schemas.member?(name) }
   end
   
   def self.define( name, &block )
      @@monitor.synchronize do
         new( name, &block ).tap do |schema|
            @@schemas[name] = schema
         end
      end
   end
   
   def connect( database_url, prefix = nil, user = nil, password = nil )
      Schemaform.connect(self, database_url, prefix, user, password)
      map = Mapping::Map.build( self, database_url )
      fail

      account  = user ? Runtime::Account.new( user, password ) : nil
      database = Runtime::Database.for( database_url, account )
      coupling = database.couple_with( schema, "sqlite://cms.rb", "cms", account )
      coupling.connect( account )
   end
   
   
   
   # ==========================================================================================
   #                                     Definition Language
   # ==========================================================================================
   
   def define_tuple( name, &block )
      @tuples.register Tuple.new(self, name, &block)
   end
   
   
   class DefinitionLanguage
      include QualityAssurance
      
      def initialize( schema )
         @schema = schema 
      end
      

      #
      # Defines an entity within the Schema.
   
      def define_entity( name, parent = nil, &block )
         if parent && !parent.is_an?(Entity) then
            parent = @schema.entities.find(parent, checks_enabled?)
         end
         
         @schema.instance_eval do
            check do
               assert(!@relations.member?(name), "#{full_name} already has a relation named [#{name}]")
            end
            
            entity = Entity.new(name, parent, self, &block)
            @relations.register(entity)
            @entities.register(entity)
         end
      end
      
      
      #
      # Defines a tuple within the Schema.
      
      def define_tuple( name, &block )
         @schema.define_tuple(name, &block)
      end
   
   
      #
      # Defines a simple (non-entity) type.  
   
      def define_type( name, base_name = nil, modifiers = {} )
         @schema.instance_eval do
            check do
               type_check( :name, name, [Symbol, Class] )
               type_check( :modifiers, modifiers, Hash )
            end

            if base_name && !@types.member?(base_name) then
               fail "TODO: deferred types"
            else
               modifiers[:name     ] = name
               modifiers[:base_type] = base_name
               modifiers[:context  ] = self
               
               @types.register UserDefinedType.new(modifiers)
            end
         end
      end
      
      
      #
      # Adds attributes to an existing tuple type.
      
      def augment_tuple( name, &block )
         tuple_type = @schema.find_tuple_type(name) 
         tuple_type.define( &block )
      end
   end
   
   
   # ==========================================================================================
   #                                       Public Interface
   # ==========================================================================================

   attr_reader :supervisor, :types, :entities, :relations, :tuples, :dsl

   def identifier_type()
      @types[:identifier]
   end
   


   # 
   # 
   # def each_entity() 
   #    @entities.each do |name, entity|
   #       yield( entity )
   #    end
   # end
   # 
   # def each_tuple_type()
   #    @types.each do |name, type|
   #       resolved = type.resolve()
   #       yield( resolved ) if resolved.tuple_type?
   #    end
   # end
   # 
   #    
   # 
   # 
   # #
   # # Returns the TupleType (type) for a name, or nil.
   # 
   # def find_tuple_type( name, fail_if_missing = true )
   #    return name if name.is_a?(TupleType)
   #    type_check( :name, name, Symbol )
   #    
   #    return @tuple_types[name] if @tuple_types.member?(name)
   #    return nil unless fail_if_missing
   #    fail( "unrecognized tuple type [#{name}]" )
   # end
   # 
   # 
   # #
   # # Returns an Entity or other named Relation for a name (Symbol), or nil.
   # 
   # def find_relation( name, fail_if_missing = true )
   #    return name if name.is_a?(Relation)
   #    type_check( :name, name, Symbol )
   #    
   #    return @relations[name] if @relations.member?(name)
   #    return nil unless fail_if_missing
   #    fail( "unrecognized relation [#{name}]" )
   # end
   # 
   # #
   # # Returns an Entity (only) for a name (Symbol), or nil.
   # 
   # def find_entity( name, fail_if_missing = true )
   #    return name if name.is_a?(Entity)
   #    type_check( :name, name, Symbol )
   #    
   #    return @entities[name] if @entities.member?(name)
   #    return schema.find_entity(name, fail_if_missing) if schema
   #    return nil unless fail_if_missing
   #    fail( "unrecognized entity [#{name}]" )
   # end
   # 



protected

   # ==========================================================================================
   #                                          Internals
   # ==========================================================================================

   def initialize( name, &block )
      super( nil, name )
      
      @dsl         = DefinitionLanguage.new(self)
      @tuples      = Registry.new(self, "a tuple")
      @relations   = Registry.new(self, "a relation")
      @entities    = Registry.new(self, "an entity")
      @types       = TypeRegistry.new(self)
      @supervisor  = ResolutionSupervisor.new(self)
         
      @types.register CatchAllType.new(:name => :all       , :context   => self)
      @types.register     VoidType.new(:name => :void      , :base_type => @types[:all])
      @types.register         Type.new(:name => :any       , :base_type => @types[:all])
                                                           
      @types.register   StringType.new(:name => :binary    , :base_type => @types[:any]) ; warn_once( "BUG: does the binary type need a different loader?" )
      @types.register   StringType.new(:name => :text      , :base_type => @types[:any])
      @types.register  BooleanType.new(:name => :boolean   , :base_type => @types[:any])
      @types.register DateTimeType.new(:name => :datetime  , :base_type => @types[:any])
      @types.register  NumericType.new(:name => :real      , :base_type => @types[:any] , :default => 0.0 )
      @types.register  IntegerType.new(:name => :integer   , :base_type => @types[:real]   )
      @types.register  NumericType.new(:name => :identifier, :base_type => @types[:integer])
      
      @dsl.instance_eval do
         define_type :symbol, :text, :length => 80, :check => lambda {|i| !!i.to_sym && i.to_sym.inspect !~ /"/}
      end
      
      @dsl.instance_eval(&block) if block_given?
   end
   
   
   
   
   
   # ==========================================================================================
   #                                           Mapping
   # ==========================================================================================
   
   #
   # Maps the Schema into runtime representation.
   
   def lay_out()
      if @layout.nil? then
         @layout = Layout::Schema.new(self)
         @entities.each do |entity|
            entity.lay_out( @layout )
         end
      end
      
      @layout
   end
   
   
   
   
end # Schema
end # Definitions
end # Schemaform


Dir[Schemaform.locate("schema/*.rb")].each{|path| require path}
