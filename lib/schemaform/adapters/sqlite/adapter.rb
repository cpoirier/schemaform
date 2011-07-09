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

require 'sqlite3'

#
# Walks a Schema to lay out structures in tables and fields.

module Schemaform
module Adapters
module SQLite
class Adapter < Generic::Adapter
   
   def self.build( coordinates )
      adapter = nil
      if path = File.expand_path(coordinates.fetch(:path, nil)) then
         @@monitor.synchronize do
            unless @@adapters.member?(path)
               @@adapters[path] = adapter = new(path)
            end
         end
      end
      
      return adapter
   end
   
   def connect()
      connection = Connection.new(self) 
      if block_given? then
         begin
            yield(connection)
         ensure 
            connection.close()
         end
      else
         connection
      end
   end
   
   attr_reader :path

   def escape_string( string )
      ::SQLite3::Database.quote(string)
   end

   def table_class() ; SQLite::Table ; end
   def separator()   ; "$" ; end
   
   
protected
   def initialize( path, url = nil )
      super(url || "sqlite:#{path}")
      @path = path
   end
   
   @@monitor  = Monitor.new()
   @@adapters = {}
   

end # Adapter
end # SQLite
end # Adapters
end # Schemaform

Schemaform::Adapters.register(:sqlite, :SQLite)


