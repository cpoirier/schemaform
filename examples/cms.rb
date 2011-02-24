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

require 'ipaddr'


#
# An example Schema definition: a schema for a content management system.

def define_example_cms_schema()
   
   Schemaform.define :CMS do
      
      
      #=== Access Control =====================================================================
      
      #
      # Each Role has a set of direct capabilities, stored in RoleCapability.  Each Role can 
      # also inherit additional capabilities from one or more parent roles (and their parents,
      # and so on).  Each Account (below) has exactly one Role, and draws the Role's full 
      # set of direct and inherited capabilities.
      
      define_entity :Roles do
         each :Role do
            required :name                  , String, :length => 40
            required :capabilities          , set_of(:Capabilities)
            required :parents               , set_of(:Roles       )
            # derived  :ancestors             , lambda {|role| role.parents.follow(:Roles, :parents).as_set() }
            # derived  :inherited_capabilities, lambda {|role| role.ancestors.capabilities }
            # derived  :all_capabilities      , lambda {|role| role.capabilities + role.inherited_capabilities }
            optional :something, :RoleSomething do
               required :x, String
               optional :y, String
               derived  :z, lambda {|role| role.parents}
            end
         end
         
         key :name
      end

      
      define_entity :Capabilities do
         each :Capability do
            required :name, String, :length => 40
            # derived  :used_in, lamda {|capability| capability.find_matching(:Roles, :parents)}
         end
         
         key :name
      end


         

      #=== Account management =================================================================

      define_entity :Accounts do
         each :Account do
            required :email_address  , String, :length => 50
            required :display_name   , String, :length => 50
            required :safe_name      , String, :length => 50
            required :role           , member_of(:Roles)
            required :lockedout_until, Time, :default => Time.at(0)
            # TODO: field :hashed_password, SHA1 -- what to we want this to do; should it be excluded from retrieve?
         end
         
         key :safe_name
         key :email_address
      end

      define_entity :AuthenticationAttempts do
         each :AuthenticationAttempt do
            required :account, member_of(:Accounts)
            required :time   , Time
            required :from   , IPAddr
            required :result , member_of(:AuthenticationResults)
         end
         key :account, :time
      end

      define_entity :AuthenticationResults do
         enumerate :valid, :invalid
      end
      
      
      
   end

end


#
# If called directly, set up the environment and run some tests.

if $0 == __FILE__ then
   
   begin
      require "../lib/schemaform.rb"
      define_example_cms_schema()
      p CMS.ancestors
      p CMS::AuthenticationAttempts.ancestors
      # connection = Schemaform.connect( example_cms_schema(), "sqlite://cms.rb", "cms" )
   
   rescue SystemExit ; raise
   rescue Interrupt, Errno::EPIPE ; exit
   rescue Exception => e
      raise unless e.respond_to?("generate_report")
      exit e.generate_report()
   end
   
end


