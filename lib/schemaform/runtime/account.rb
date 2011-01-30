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

require "monitor"


#
# Wraps up basic functionality for objects that need account credentials.

module Schemaform
module Runtime
class Account
   include QualityAssurance

   def initialize( name, password )
      @name     = name
      @password = password
   end
   
   #
   # Returns the account name.
   
   def name( fallback_account = nil )
      return @name         unless @name.nil?
      return fallback.name unless fallback.nil?
      return nil
   end
   
   #
   # Returns the account password.
   
   def password( fallback_account = nil )
      return @password         unless @name.nil?      # We don't default just password -- they go as a pair
      return fallback.password unless fallback.nil?
      return nil
   end
   
   
end # Account
end # Runtime
end # Schemaform