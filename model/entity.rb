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
# A single entity within the schema.

module SchemaForm
module Model
class Entity
      
   def initialize( name, parent = nil, &block )
      @name   = name
      @parent = parent
      @fields = {}
      instance_eval(&block) if block_given?
   end
   
   
   #
   # Defines a field within the entity.  If a block is given, the field is calculated,
   # and the type will be determined for you.  Otherwise, you must supply at least a type.
   
   def field( name, *data, &block )
      assert( !@fields.member?(field.name), "duplicate field name #{field.name}" )      
      
      if block_given? then
         
      else
      end
      
      
      register_field( Fields::StoredField.new(name, type) )
   end


protected

   def register_field( field )
   end
      

   
end # Entity
end # Model
end # SchemaForm


require $schemaform.relative_path("field.rb")
