#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
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
# comment

module Schemaform
class Schema

   #
   # Brings the database schema up to date.
   
   def upgrade(database, prefix = nil)
      
      layout = lay_out(sequel.database_type, prefix)
      sequel.transaction do
         layout.tables.each do |table|
            sequel.execute_ddl(table.to_sql_create) unless sequel.table_exists?(table.name.to_s)
         end
      end
   end

end # Schema
end # Schemaform