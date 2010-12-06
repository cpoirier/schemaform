#!/usr/bin/env ruby -KU
# =============================================================================================
# SchemaForm
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

require 'ipaddr'


#
# An example Schema definition: a schema for a content management system.

def example_cms_schema()
   SchemaForm::Model::Schema.define :CMS do
      
      map IPAddr => text_type(40)
      
      
      #=== Access Control =====================================================================
      
      #
      # Each Role has a set of direct capabilities, stored in RoleCapability.  Each Role can 
      # also inherit additional capabilities from one or more parent roles (and their parents,
      # and so on).  Each Account (below) has exactly one Role, and draws the Role's full 
      # set of direct and inherited capabilities.
      
      define :Role do
         field :name                  , text_type(40)
         field :parents               , lambda {|role| role.find_matching(:RoleInheritance).return_only(:parent => :role)}
         field :ancestors             , lambda {|role| role.find_matching(:RoleInheritance).follow(:RoleInheritance, :role, :parent).return_only(:parent => :role)}
         field :closure               , lambda {|role| relation(:role => role.id) + role.ancestors}
         field :capabilities          , lambda {|role| role.closure.join(:RoleCapability).return_only(:capability)}
         field :inherited_capabilities, lambda {|role| role.ancestors.join(:RoleCapability).return_only(:capability)}
      end

      define :Capability do
         field :name, text_type(40)
      end

      define :RoleInheritance do
         field :role  , :Role
         field :parent, :Role
      end

      define :RoleCapability do
         field :role      , :Role
         field :capability, :Capability
      end


      #=== Account management =================================================================

      define :Account do
         field :email_address  , text_type(50)
         field :display_name   , text_type(50)
         field :safe_name      , text_type(50)
         # TODO: field :hashed_password, SHA1 -- what to we want this to do; should it be excluded from retrieve?
         field :role           , :Role
         field :lockedout_until, Time, :default => Time.at(0)

         key :safe_name
         key :email_address
      end

      define :AuthenticationAttempt do
         field :account, :Account
         field :time   , Time
         field :from   , IPAddr
         field :result , :AuthenticationResult
      end

      define :AuthenticationResult do
         enumerate :valid, :invalid
      end
   end

end


#
# If called directly, set up the environment and run some tests.

if $0 == __FILE__ then
   
   require "#{File.dirname(File.expand_path(__FILE__))}/../tools/command_processor.rb"
   CommandProcessor.process(ARGV, :exit => true) do |$schemaform, flags, files|
      require $schemaform.library_path("model/schema.rb")
      schema = example_cms_schema()
   end

end