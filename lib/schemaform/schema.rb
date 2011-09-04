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

require 'monitor'


#
# Provides a naming context and a unit of storage within the Schemaform system.

module Schemaform
class Schema
   include QualityAssurance
   
   
   
   # ==========================================================================================
   #                                       Public Interface
   # ==========================================================================================

   attr_reader :supervisor, :types, :entities, :tuples, :dsl, :name, :version
   
   def path()
      [@name]
   end
   
   def schema()
      self
   end

   def unknown_type()
      @types[:unknown]
   end
   
   def any_type()
      @types[:any]
   end
   
   def identifier_type()
      @types[:identifier]
   end
   
   def integer_type()
      @types[:integer]
   end
   
   def boolean_type()
      @types[:boolean]
   end
   
   def text_type( length = nil )
      if length then
         @types[:text].make_specific(:length => length)
      else
         @types[:text]
      end
   end
   
   def build_list_type( member_type )
      ListType.build(member_type, :context => self)
   end
   
   def build_set_type( member_type )      
      SetType.build(member_type, :context => self)
   end
   
   def couple( database_url, settings = {} )
      account  = settings.fetch(:account, settings.member?(:user) ? Runtime::Account.new(settings[:user], settings.fetch(:password)) : nil)
      database = Runtime::Database.for(database_url, account)
      database.couple_with(self, settings.fetch(:prefix, nil), account)
   end 
   
   def register_tuple( tuple )
      @tuples.register(tuple)
   end
   
   
   def print_to( printer )
      printer.label "Schema #{@name}, version #{@version}" do
         @entities.each do |entity|
            entity.print_to(printer)
         end
      end
   end   
   

   def schema_id()
      @schema_id ||= name().to_s + "$" + @version.to_s
   end
   
   def hash()
      schema_id.hash()
   end
   
   def ==( rhs )
      return super unless rhs.responds_to?(:schema_id)
      return schema_id() == rhs.schema_id()
   end

   def verify()
      @tuples.each{|tuple| tuple.verify()}
   end


protected

   # ==========================================================================================
   #                                          Internals
   # ==========================================================================================

   def initialize( name, version, &block )      
      @name        = name
      @version     = version
      @tuples      = Registry.new("schema [#{@name}]", "a tuple"  )
      @entities    = Registry.new("schema [#{@name}]", "an entity")
      @types       = TypeRegistry.new("schema [#{@name}]")
      @monitor     = Monitor.new()
      @schema_id   = {}
         
      @types.register  UnknownType.new(:name => :unknown   , :context => self )
      @types.register     VoidType.new(:name => :void      , :base_type => @types[:unknown])
      @types.register         Type.new(:name => :any       , :base_type => @types[:unknown])
                                                           
      @types.register   StringType.new(:name => :binary    , :base_type => @types[:any]) ; warn_once( "BUG: does the binary type need a different loader?" )
      @types.register   StringType.new(:name => :text      , :base_type => @types[:any])
      @types.register  BooleanType.new(:name => :boolean   , :base_type => @types[:any])
      @types.register DateTimeType.new(:name => :datetime  , :base_type => @types[:any])
      @types.register  NumericType.new(:name => :real      , :base_type => @types[:any] , :default => 0.0 )
      @types.register  IntegerType.new(:name => :integer   , :base_type => @types[:real]   )
      @types.register  NumericType.new(:name => :identifier, :base_type => @types[:integer])

      @types.register UserDefinedType.new(:name => :ip, :base_type => @types[:text].make_specific(:length => 15))
      
      # @dsl.instance_eval do
      #    define_type :symbol, :text, :length => 80, :check => lambda {|i| !!i.to_sym && i.to_sym.inspect !~ /"/}
      # end
      # 
      # @dsl.instance_eval(&block) if block_given?
   end
   
   
   
end # Schema
end # Schemaform


Dir[Schemaform.locate("schema/*.rb")].each{|path| require path}
