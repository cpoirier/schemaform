#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
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

require Schemaform.locate("../expression.rb")


#
# Indicates the present? flag of the source should be checked.

module Schemaform
module Definitions
module Expressions
class PresentCheck < Expression

   def initialize( source, if_present, otherwise )
      super(source)
      @if_present = if_present
      @otherwise  = otherwise
   end

end # PresentCheck
end # Expressions
end # Definitions
end # Schemaform