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

require Schemaform.locate("placeholder.rb")


#
# Provides access to a whole Entity. 

module Schemaform
module Language
module Placeholders
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
   
   def get_definition()
      @entity
   end
   

end # Entity
end # Placeholders
end # Language
end # Schemaform
