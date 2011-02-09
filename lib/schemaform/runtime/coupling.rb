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


#
# Couples a Schema to a Database, allowing you to create Connections for use.

module Schemaform
module Runtime
class Coupling
   include QualityAssurance

   def connect( account = nil, for_reading = false )
      assert( !for_reading, "read-only support not yet implemented" )
      
   end
   
   def connect_for_reading( account = nil )
      connect( account, true )
   end
   
   

   attr_reader :database, :schema, :prefix
   attr_writer :account
   
   def account()
      return @account unless @account.nil?
      return @database.master_account
   end


   def initialize( database, schema, prefix = nil, account = nil )
      check do
         type_check( :database, database, Database )
         type_check( :schema  , schema  , Definitions::Schema )
      end
      
      @database = database
      @schema   = schema
      @prefix   = prefix
      @account  = account
   end
   
   
end # Coupling
end # Runtime
end # Schemaform