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
# Base class for Adapter exceptions. Individual adapters can just raise one of these if the
# underlying database library doesn't provide a hierarchy of exceptions. If they do, you should
# wrap them in subclasses of this.

module Schemaform
module Adapters
module GenericSQL
class Error < ::Exception

   def initialize( message, underlying_exception )
      super(message || underlying_exception.message)
      @underlying_exception = underlying_exception
   end
   
   attr_reader :underlying_exception
   

end # AdapterError
end # GenericSQL
end # Adapters
end # Schemaform