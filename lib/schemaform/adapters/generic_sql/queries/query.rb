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
# Base class for any SQL relation.

module Schemaform
module Adapters
module GenericSQL
module Queries
class Query 
   include QualityAssurance
   
   def initialize( adapter )
      @adapter = adapter
      @sql     = nil
   end
   
   attr_reader :adapter

   def fields()
      warn_unless_overridden self, :fields
   end
   
   def source()
      warn_unless_overridden self, :source
   end
   
   def execute( connection, parameters = [] )
      @sql = @adapter.render_sql_query(self) if @sql.nil?
      connection.retrieve(@sql, *parameters)
   end
   
   
end # Query
end # Queries
end # GenericSQL
end # Adapters
end # Schemaform