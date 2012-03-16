#!/usr/bin/env ruby -KU
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

require Schemaform.locate("component.rb")


#
# An element in the structure of an Entity.

module Schemaform
module Model
class Element < Component
   
   def initialize( type, name = nil )
      type_check(:type, type, Type)
      super(name)
      @type = type
   end

   attr_reader :type
   
   def has_attributes?()
      false
   end
   
   def attribute?(name)
      false
   end
   
   def print_to( printer, name_override = nil )
      if self.class == Element then
         type.print_to(printer)
      else
         super
      end
   end
   
   def context_collection()
      each_context do |current|
         return current if current.is_a?(Collection)
      end
   end
   
   def verify()
      @type.verify()
   end
   
end # Element
end # Model
end # Schemaform

