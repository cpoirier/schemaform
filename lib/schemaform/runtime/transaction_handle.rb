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
# Represents a single transaction on a Database.  

module Schemaform
module Runtime
class TransactionHandle

   def initialize( database, sequel_connection )
      @database          = database
      @sequel_connection = sequel_connection
      @thread            = Thread.current
   end
   
   def close()
      @sequel_connection = nil
   end
   
   def closed?()
      @sequel_connection.nil?
   end
   

end # Transaction
end # Runtime
end # Schemaform