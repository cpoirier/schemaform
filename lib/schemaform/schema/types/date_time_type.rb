#!/usr/bin/env ruby -KU
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

require Schemaform.locate("scalar_type.rb")


module Schemaform
class Schema
class DateTimeType < ScalarType

   def initialize( attrs )
      attrs[:default] = load("0000-01-01 00:00:00") unless attrs.member?(:default)
      super
   end

   #
   # Instructs the type to produce a memory representation of a stored value.
   
   def load( stored_value )
      return super if @loader
      year, month, day, hour, minute, second, micros = *stored_value.split(/[^\d]+/)
      DateTime.civil(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i, second.to_i)
   end
   
   
   #
   # Instructs the type to produce a storable value from a memory representation.
   
   def store( memory_value )
      return super if @storer
      case memory_value
      when Time
         utc = memory_value.getutc
         utc.strftime("%Y-%m-%d %H:%M:%S") + (utc.usec > 0 ? ".#{utc.usec}" : "")
      when Date, DateTime
         memory_value.iso8601
      end
   end

end # BooleanType
end # Schema
end # Schemaform