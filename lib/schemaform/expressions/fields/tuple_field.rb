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
# An expression wrapper for a TupleField

module Schemaform
module Expressions
module Fields
   
class TupleField < Field

   def initialize( definition )
      super( definition )
      @tuple = definition.tuple.expression

      @tuple.fields.each do |name, field|
         instance_class.class_eval do
            define_method field.name do |*args|
               return field
            end
         end
      end
   end

end # TupleField

end # Fields
end # Expressions
end # Schemaform