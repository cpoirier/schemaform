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

require Schemaform.locate("element.rb")


module Schemaform
class Schema
class Scalar < Element

   def initialize( type, context = nil )
      super(context || type.context, nil)
      @type = type
   end
   
   attr_reader :type

   def marker( production = nil )
      type.marker(production)
   end

   def recreate_in( new_context, changes = nil )
      super.tap do |new_scalar|
         new_scalar.instance_eval{ @type = @type.recreate_in(new_context)}
      end
   end


end # Scalar
end # Schema
end # Schemaform