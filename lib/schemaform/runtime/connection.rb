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

require 'rubygems'
require 'sequel'


#
# Provides the primary bridge between a Schema and the physical storage in which is lives.  

module Schemaform
module Runtime
class Connection

   def initialize( schema, connection_string, properties = {} )
      assert( !properties.member?(:server), "in order to maintain proper transaction protection, the Sequel :servers parameter cannot be used with Schemaform" )

      @schema    = schema.top
      @read_only = !!properties.delete(:read_only)
      @prefix    = properties.delete(:prefix)
      @sequel    = Sequel.connect( connection_string, properties )
      
      update_database_structures
   end
   
   
   
   
   def update_database_structures()
      @sequel[]
   end
   

end # Runtime
end # Connection
end # Schemaform