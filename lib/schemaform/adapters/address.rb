#!/usr/bin/env ruby
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2012 Chris Poirier
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
# Base class for things that locate a database for connection.

module Schemaform
module Adapters
class Address

   def initialize( url, coordinates = {} )
      @url         = url
      @coordinates = coordinates
   end
   
   attr_reader :url
   
   def []( name )
      @coordinates[name]
   end
   
   def fetch( name, default = nil )
      warn_todo("correct Address::fetch() default handling")
      @coordinates.fetch(name, default)
   end
   
   def method_missing( symbol, *args, &block )
      return super unless args.empty? && block.nil?
      return super unless @coordinates.member?(symbol)
      self[symbol]
   end
   
   def respond_to?(symbol)
      @coordinates.member?(symbol) || super
   end

end # Address
end # Adapters
end # Schemaform
