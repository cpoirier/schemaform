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
class Schema
   include QualityAssurance
   
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
   #                                       Public Interface
   # ==========================================================================================

   attr_reader :supervisor, :types, :entities, :relations, :tuples, :dsl, :name
   
   def schema()
      self
   end

   def identifier_type()
      @types[:identifier]
   end
   
   def boolean_type()
      @types[:boolean]
   end
   
   def couple( database_url, settings = {} )
      account  = settings.fetch(:account, settings.member?(:user) ? Runtime::Account.new(settings[:user], settings.fetch(:password)) : nil)
      database = Runtime::Database.for(database_url, account)
      database.couple_with(self, settings.fetch(:prefix, nil), account)
   end 
   




protected

   # ==========================================================================================
   #                                          Internals
   # ==========================================================================================

   def initialize( name, &block )      
      @name        = name
      @tuples      = Registry.new("schema [#{@name}]", "a tuple"              )
      @relations   = Registry.new("schema [#{@name}]", "a relation"           )
      @entities    = Registry.new("schema [#{@name}]", "an entity", @relations)
      @types       = TypeRegistry.new("schema [#{@name}]")
      @supervisor  = ResolutionSupervisor.new(self)
         
      @types.register CatchAllType.new(:name => :all       , :context => self )
      @types.register     VoidType.new(:name => :void      , :base_type => @types[:all])
      @types.register         Type.new(:name => :any       , :base_type => @types[:all])
                                                           
      @types.register   StringType.new(:name => :binary    , :base_type => @types[:any]) ; warn_once( "BUG: does the binary type need a different loader?" )
      @types.register   StringType.new(:name => :text      , :base_type => @types[:any])
      @types.register  BooleanType.new(:name => :boolean   , :base_type => @types[:any])
      @types.register DateTimeType.new(:name => :datetime  , :base_type => @types[:any])
      @types.register  NumericType.new(:name => :real      , :base_type => @types[:any] , :default => 0.0 )
      @types.register  IntegerType.new(:name => :integer   , :base_type => @types[:real]   )
      @types.register  NumericType.new(:name => :identifier, :base_type => @types[:integer])
      
      # @dsl.instance_eval do
      #    define_type :symbol, :text, :length => 80, :check => lambda {|i| !!i.to_sym && i.to_sym.inspect !~ /"/}
      # end
      # 
      # @dsl.instance_eval(&block) if block_given?
   end
   
   
   
   
end # Schema
end # Schemaform


Dir[Schemaform.locate("schema/*.rb")].each{|path| require path}
