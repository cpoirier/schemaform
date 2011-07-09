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
# Adds a prefix to a Schema name, for situations in which you need multiple copies of a 
# Schema in the same physical database.

module Schemaform
module Runtime
class PrefixedSchema

   def initialize( schema, prefix )
      @schema    = schema
      @prefix    = prefix
   end
   
   attr_reader :schema, :prefix
   
   def name()
      @name ||= @prefix.to_s + "$" + @schema.name      
   end
   
   def schema_id()
      @schema_id ||= @prefix.to_s + "$" + @schema.schema_id
   end
   
   def hash()
      schema_id.hash()
   end
   
   def eql?( rhs )
      return super unless rhs.responds_to?(:schema_id)
      return schema_id() == rhs.schema_id()
   end
   
   def method_missing( symbol, *args, &block )
      @schema.send(symbol, *args, &block)
   end


end # PrefixedSchema
end # Runtime
end # Schemaform




#
# Adds a convenience method to Schema to produce a PrefixedSchema.

module Schemaform
class Schema

   #
   # A convenience method to produce a PrefixedSchema from the Schema.
   
   def prefix( prefix )
      Runtime::PrefixedSchema.new(self, prefix)
   end
   
end # Schema
end # Schemaform
