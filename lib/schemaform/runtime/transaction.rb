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


#
# Provides a transaction scope and access to the entities for associated Schemas.

module Schemaform
module Runtime
class Transaction

   def initialize( workspace, connection )
      @workspace  = workspace
      @adapter    = connection.adapter
      @connection = connection
      @monitor    = Monitor.new()
      
      @connected_relations = {}
   end
   
   attr_reader :workspace, :connection
         
      
   #
   # Returns a runtime, connected version of the named relation for you to use. Address formats are:
   #  * relation_name
   #  * schema_name, relation_name
   #  * schema_name, schema_version, relation_name

   def []( *relation_address )
      relation = @workspace[*relation_address]
      @connected_relations[relation] || @monitor.synchronize{@connected_relations[relation] ||= ConnectedRelation.new(self, relation)}
   end
   
   
   #
   # Calls your block once for each Tuple in the retrieved query results. Returns the number
   # of rows retrieved (and processed by your block).
   
   def retrieve( query, parameters = [] )
      @adapter.plan(query).execute_for_retrieval(@connection, parameters) do |row|
         yield(Tuple.new(row))
      end
   end
   


end # Transaction
end # Runtime
end # Schemaform
