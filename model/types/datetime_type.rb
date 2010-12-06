#!/usr/bin/env ruby -KU
# =============================================================================================
# SchemaForm
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
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
# The SchemaForm datetime type.  Generally maps to Time or Date in Ruby and either dateime in 
# the database.

module SchemaForm
module Model
module Types
class DatetimeType < Type

   def initialize()
   end
   
   def simple_type?()
      return true
   end
   
   def to_s()
      "datetime()"
   end
   
   def hash()
      "DatetimeType".hash
   end
   
   def eql?( rhs )
      rhs.is_a?(DatetimeType)
   end

end # DatetimeType < Type
end # Types
end # Model
end # SchemaForm