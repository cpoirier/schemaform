#!/usr/bin/env ruby
# =============================================================================================
# SchemaForm
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Contact]   Chris Poirier (cpoirier at gmail dt com)
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

require $product.system_path("schemaform/types.rb")



#
# Maps a Ruby type to a database-field-compatible type and back again.

module SchemaForm
module Model
class TypeMapping
   
   def initialize( ruby_type, schema_type, ruby_to_schema_mapper = nil, schema_to_ruby_mapper = nil )
      @ruby_type             = ruby_type
      @schema_type           = schema_type
      @ruby_to_schema_mapper = ruby_to_schema_mapper
      @schema_to_ruby_mapper = schema_to_ruby_mapper      
   end
   
   


end # TypeMapping
end # Model
end # SchemaForm