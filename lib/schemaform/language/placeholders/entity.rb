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
# Provides access to a whole Entity. 

module Schemaform
module Language
class Entity < Placeholder

   def initialize( entity, production = nil )
      super(entity.type, production)
      @entity = entity
   end
   
   def method_missing( symbol, *args, &block )
      super
   end
   
   def get_description()
      "0x#{self.object_id.to_s(16)} #{@entity.name} #{@type.description}"      
   end
   

end # Entity
end # Language
end # Schemaform
