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


#
# An Attribute in a Tuple. Attributes are bound to the specific Tuple in which they are created. 
# If you need to copy an Attribute into another Tuple, use +duplicate()+.

module Schemaform
class Schema
class Attribute < Element
   
   def initialize( name, tuple, definition )
      type_check(:tuple, tuple, Tuple)
      super(tuple, name)
      @definition = definition
   end

   attr_reader :definition
   
   def type()
      @definition.type
   end
   
   def recreate_in( new_context, changes = nil )
      self.class.new(@name, new_context, definition.recreate_in(new_context))
   end
   
   
end # Attribute
end # Schema
end # Schemaform


Dir[Schemaform.locate("attribute_types/*.rb")].each {|path| require path}
