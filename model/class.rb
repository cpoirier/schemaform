#!/usr/bin/env ruby -KU
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


#
# Defines a si
# Provides a naming context and a unit of storage within the SchemaForm system.  Multiple
# Schemas can coexist within one physical database, but names are unique.

module SchemaForm
module Model
class Class
      
   def initialize( name, &block )
      @name   = name
      @fields = Namespace.new()
      instance_eval(&block) if block_given?
   end
   
   
   #
   # Defines a stored (as opposed to derived) field for the class.
   
   def stored( name, type, default = nil, &block )
      register_field( Fields::StoredField.new(name, type) )
   end


protected

   def register_field( field )
      assert( !@fields.member?(field.name), "duplicate field name #{field.name}" )      
   end
      

   
end # Class
end # Model
end # SchemaForm