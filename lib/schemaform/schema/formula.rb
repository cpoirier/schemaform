#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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
# An expression-valued vessel.

module Schemaform
class Schema
class Formula < Element

   def initialize( proc, context, *parameters )
      super(context)
      
      check do
         parameters.each do |parameter|
            type_check(:parameter, parameter, Element)
         end
      end
      
      @proc       = proc
      @parameters = parameters
   end
   
   attr_reader :proc
      
   def type()
      marker.type
   end
   
   def recreate_in( new_context, changes = nil )
      self.class.new(@proc, new_context)
   end


end # Expression
end # Schema
end # Schemaform

