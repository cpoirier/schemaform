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
# A type that represents a reference to an entity.

module Schemaform
module Definitions
class ReferenceType < Type

   def initialize( entity )
      super( entity.context, entity.name )
      @entity = entity
   end
   
   def tuple_name()
      @entity.heading.name
   end
   
   def type_info()
      TypeInfo::TUPLE
   end
   
   def resolve()
      supervisor.monitor(self) do
         annotate_errors( :check => "be sure the primary key of #{@entity.full_name} doesn't reference an entity which references [#{@entity.full_name}] in its primary key" ) do
            @entity.primary_key.resolve()
         end
      end
   end

end # ReferenceType
end # Definitions
end # Schemaform