#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2009 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================

require "#{File.dirname(File.expand_path(__FILE__))}/context_stream.rb"
require "#{File.dirname(File.expand_path(__FILE__))}/flag_set.rb"


#
# A ContextStream for managing debug output.  Integrates a FlagSet for managing debug scopes.

class DebugStream < ContextStream

   attr_reader :flag_set
   
   def initialize( stream, indent = "", product = nil, dump_inspector = :pretty_inspect )
      super( stream, indent )
      @flag_set       = FlagSet.new( true )
      @dump_inspector = dump_inspector
      @product        = product
      @warned_once    = {}
   end
   
   def enable( *scopes )
      @flag_set.flag( *scopes )
   end
   
   def enabled?( *scopes )
      return @flag_set.flagged?( *scopes )
   end
   
   def explicitly_enabled?( *scopes )
      return @flag_set.explicitly_flagged?( *scopes )
   end
   
   def warn( message, location = nil )
      location = caller()[0] if location.nil?
      self.puts( "Warning at #{@product ? @product.relative_install_directory(location) : location}:" )
      self.indent() { self.puts(message) }
   end
   
   def warn_once( message )
      location = caller()[0]
      if not @warned_once.member?(location)
         self.warn(message, location)
         @warned_once[location] = true
      end
   end
   
end # DebugStream


