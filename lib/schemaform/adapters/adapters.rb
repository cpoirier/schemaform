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

module Schemaform
module Adapters
   extend QualityAssurance 
   
   #
   # Retrieves the adapter for the specified address.
   
   def self.[]( address )
      load(address.fetch(:engine))::Adapter.build(address)
   end
   
   
   #
   # Registers an engine with the system.
   
   def self.register( engine, module_name )
      assert(!@@engines.member?(engine), "engine [#{engine}] already registered")
      @@engines[engine] = module_name
   end
   
   
protected

   def self.load( engine )
      @@monitor.synchronize do
         unless @@loaded.member?(engine) 
            if @@engines.member?(engine) && Adapters.const_defined?(@@engines[engine]) then
               @@loaded[engine] = true
            else            
               path = Schemaform.locate("#{engine}")
               assert(File.directory?(path), "cannot load Adapter for [#{engine}]")
            
               Dir["#{path}/*.rb"].each{|path| require path}
               @@loaded[engine] = true
            
               unless @@engines.member?(engine)
                  module_name = engine.to_s.camel_case.intern
                  assert(Adapters.const_defined?(module_name), "cannot find Adapter module for [#{engine}]")
                  @@engines[engine] = module_name
               end
            end
         end
      end

      Adapters.const_get(@@engines[engine])
   end
   

   @@monitor = Monitor.new()
   @@loaded  = {}
   @@engines = {}
   
   
   
end # Adapters
end # Schemaform


Dir[Schemaform.locate("generic_sql/*.rb")].each{|path| require path}
