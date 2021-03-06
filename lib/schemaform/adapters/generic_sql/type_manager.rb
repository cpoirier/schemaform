#!/usr/bin/env ruby
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
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
# Represents a SQL type within the system.

module Schemaform
module Adapters
module GenericSQL
class TypeManager
   include QualityAssurance
   extend  QualityAssurance
   
   
   def initialize( adapter )
      @adapter = adapter
   end
   
   attr_reader :adapter
   
   
   def text_type( length = 0 )
      if length.exists? && length > 0 && length < 256 then
         TypeInfo.new(self, "varchar(#{length})", length + 1, true)
      else
         TypeInfo.new(self, "text", 0, true)
      end
   end
   
   def binary_type( length = 0 )
      TypeInfo.new(self, "blob", 0, true)
   end
   
   def boolean_type()
      integer_type(0..1)
   end
   
   def identifier_type()
      integer_type()
   end
   
   def integer_type( range = nil )
      TypeInfo.new(self, "integer", 4)
   end
   
   def real_type( range = nil)
      TypeInfo.new(self, "real", 8)
   end
   
   def date_time_type()
      @date_time_type ||= TypeInfo.new(self, "datetime", 24, true) do |value|
         value.is_a?(Time) ? value.strftime("%Y-%m-%d %H:%M:%S") : value
      end         
   end

   def scalar_type( type )
      case type
      when TypeInfo
         type
      when Schemaform::Model::StringType
         if type.typeof?(type.schema.text_type) then
            text_type(type.length)
         else
            binary_type(type.length)
         end
      when Schemaform::Model::BooleanType, :boolean
         boolean_type()
      when Schemaform::Model::IntegerType, :integer
         integer_type(type.range)
      when Schemaform::Model::NumericType, :real
         real_type(type.range)
      when Schemaform::Model::DateTimeType
         date_time_type()
      when Schemaform::Model::EnumeratedType
         if type.evaluated_type.is_a?(Schemaform::Model::StringType) then
            text_type(type.evaluated_type.length)
         else
            integer_type(type.evaluated_type.range)
         end
      else
         fail_todo type.class.name
      end
   end
   
end # TypeManager
end # Adapters
end # GenericSQL
end # Schemaform
