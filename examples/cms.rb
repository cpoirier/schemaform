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

class Name < String
   def +( rhs )
      Path.new( self, rhs )
   end
   
   def self.build( value )
      value.is_a?(Name) ? value : Name.new(value)
   end
end

class Path
   
   def self.parse( string )
      new( *(string.split("/")) )
   end
   
   def initialize( *components )
      @components = components.flatten.collect{ |c| Name.build(c) }
   end
   
   def to_a()
      @components
   end
   
   def to_s()
      @components.join("/")
   end
   
   def +( rhs )
      Path.new( *@components, *rhs )
   end
end


#
# An example Schema definition: a schema for a content management system.

def define_example_cms_schema()
   
   Schemaform.define :CMS do
      
      define_type Name, :text
      define_type Path, :text, :load => lambda {|v| Path.parse(v)}
      
      
      
      #=== System =============================================================================
      
      #
      # Modules are providers of functionality and managers of names.
      
      define_entity :Modules do
         each :Module do
            required :name, String, :length => 30
         end
      end

      
      #
      # Languages.
      
      define_entity :Languages do
         each :Language do
            required :name  , :String  , :length => 5
            optional :parent, :Language
         end
      end
      

      
      #=== Identity ===========================================================================
      
      define_entity :Accounts do
         each :Account do
            required :name  , String, :length => 50
            required :handle, String, :length => 50
         end
         
         key :name
         key :handle
      end
      
      define_entity :SystemAccounts do
         each :SystemAccount do 
            import :Account
            required :owner, :Module
         end
         
         overlay :Accounts
      end
      
      define_entity :UserAccounts do
         each :UserAccount do
            import :Account
            required :can_login       , :boolean
            required :locked_out_until, Time, :default => Time.at(0)
            optional :hashed_password , SHA1, :default => ""           # left blank if an OpenID
         end
         
         overlay :Accounts
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



      #=== Structure ==========================================================================


      #
      # Addressable content containers provide the structure of your website.
      
      define_entity :Containers do
         each :Container do
            maintained :path   , lambda {|container| container.context.path + container.name }
            optional   :context, :Container
            required   :name   , Name, :length => 70
            required   :type   , :ContainerType  
         end
         
         key :path
         key :context, :name
      end

      
      #
      # The master list of container types.
      
      define_entity :ContainerTypes do
         each :ContainerType do
            required :module, :Module
            required :name  , String, :length => 60
         end
         
         key :module, :name
      end
      
      
      

      #=== Access Control =====================================================================
      #
      # Provides cascading Access Control assignments on CMS Containers, such that you could 
      # (for instance) create the following rules, and get instant (read: computationally 
      # inexpensive, correct) answers:
      #
      # / enforce  "all privileges" for "administrators"
      # / allow    "read"           for "all users"
      # / prohibit "write"          for "read-only"
      #
      # /moderator-forum deny  "all privileges" for "all users"
      # /moderator-forum allow "read"           for "moderators"
      # /moderator-forum allow "write"          for "moderators"
      #
      # Note that any moderator in "read-only" will be unable to write to /moderator-forum.  
      # Also, any administrator will still have full permissions on /moderator-forum, due to
      # the "enforce" rule on /.
      
      
      define_entity :Groups do
         each :Group do
            required   :owner             , :Account
            required   :name              , String, :length => 80
            required   :base_groups       , set_of(:Groups)
            required   :excluded_groups   , set_of(:Groups)
            required   :excluded_members  , set_of(:Accounts)
            required   :additional_members, set_of(:Accounts)
            maintained :members           , lambda {|g| g.base_groups.members - g.excluded_groups.members - g.excluded_members + g.additional_members}
         end
      end


      define_entity :Capabilities do
         each :Capability do
            required   :module   , :Module
            required   :name     , String, :length => 40
            required   :parent   , :Capability
            maintained :ancestors, lambda {|c| set(c.parent) + c.parent.ancestors }
            maintained :closure  , lambda {|c| set(c) + c.ancestors }
         end
         
         key :module, :name
      end
      
      
      define_tuple :AccessRule do
         required :capability , :Capability
         required :group      , :Group
         required :is_allowed , :boolean
         required :is_enforced, :boolean

         volatile :effective_capabilities, lambda {|ar| ar.capability.closure }
      end


      augment_tuple :Container do
         optional :access_control, :default => lambda {|c| c.context.access_control } do  # Can this default be dynamic?
            required :stated_rules, list_of(:AccessRule)
            
            maintained :effective_rules do |c|
               with c.access_control.stated_rules
               ungroup :effective_capabilities => :effective_capability    # Note: the ordering of :stated_rules means the ungrouped result is ordered within each effective_capability
               
               add_volatile :effective_previous do |er|
                  er.previous.or(
                     c.context.present?(
                        c.context.access_control.tail_rules.where{|tr| tr.effective_capability = er.effective_capability }
                     )
                  )
               end
               
               add_maintained :forbidden_members do |er|
                  er.effective_previous.forbidden_members + (er.is_enforced & !er.is_allowed).ifelse(er.group.members - er.effective_previous.required_members)
               end

               add_maintained :required_members do |er|
                  er.effective_previous.required_members + (er.is_enforced & er.is_allowed).ifelse(er.group.members - er.forbidden_members)
               end
               
               add_maintained :effective_members do |er|
                  er.is_allowed.ifelse(
                     er.effective_previous.effective_members + (er.group.members - er.forbidden_members),
                     er.effective_previous.effective_members - (er.group.members - er.required_members )
                  )
               end
            end
            
            volatile   :tail_rules, {|c| c.access_control.effective_rules.last }
            maintained :privileges, {|c| c.access_control.tail_rules.effective_members }
         end
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
      p CMS::Role.ancestors
      p CMS::AuthenticationAttempts.ancestors
      # connection = Schemaform.connect( example_cms_schema(), "sqlite://cms.rb", "cms" )
   
   rescue SystemExit ; raise
   rescue Interrupt, Errno::EPIPE ; exit
   rescue Exception => e
      raise unless e.respond_to?("generate_report")
      exit e.generate_report()
   end
   
end


