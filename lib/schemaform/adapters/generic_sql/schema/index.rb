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
# An index on a table, possibly unique.

module Schemaform
module Adapters
module GenericSQL
class Index
   include QualityAssurance
   extend  QualityAssurance

   def initialize( table, name, unique = false )
      @table  = table
      @name   = name
      @unique = unique
      @fields   = Registry.new(name.to_s, "a field")
      @reversed = {}
   end
   
   attr_reader   :adapter, :name, :unique, :fields
   attr_accessor :identifier
   
   def to_sql_create()
      @adapter.render_sql_create(self)
   end
   
   def add_field( field, reverse_order = false )
      @fields.register(field)
      @reversed[field.name] = reverse_order
   end
   
end # Index
end # GenericSQL
end # Adapters
end # Schemaform


