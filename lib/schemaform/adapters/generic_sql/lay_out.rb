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

require Schemaform.locate("wrappers.rb")


module Schemaform
module Adapters
module GenericSQL
module Wrappers
   
   class Wrappers
      def lay_out()
      end
   end
   
   
   class Model
      class Schema
         def lay_out()
            @model.entities.each do |entity|
               p entity.name
               # wrapper = @adapter.wrap_model(entity)
               # wrapper.lay_out()
            end
         end      
      end
   end # Model
   
   
   class Productions
   end # Productions


end # Wrappers
end # GenericSQL
end # Adapters
end # Schemaform