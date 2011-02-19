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


#
# Base class for things that pick the appropriate Map class for a database connection URL.

module Schemaform
module Mapping
class Selector
   include QualityAssurance
   
   attr_reader :adapter_class
   
   def initialize( adapter_class )
      @adapter_class = adapter_class
   end
   
   def matches?( connection_url )
      fail_unless_overriden( self, :matches? )
   end

end # Selector
end # Mapping
end # Schemaform


Dir[Schemaform.locate("selectors/*.rb")].each do |path| 
   require path
end
