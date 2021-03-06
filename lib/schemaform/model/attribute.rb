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

require Schemaform.locate("component.rb")


#
# An Attribute in a Tuple. Attributes are bound to the specific Tuple in which they are created. 
# If you need to copy an Attribute into another Tuple, use +duplicate()+.

module Schemaform
module Model
class Attribute < Component
   
   def initialize( name, type = nil )
      super(name)
      @type = type
      @type.acquire_for(self) if @type
   end
   
   def verify()
      type.verify()
   end
   
   def type()
      @type
   end
   
   def evaluated_type()
      type.evaluated_type
   end
   
   def singular_type()
      type.singular_type
   end
   
   def recreate_in( new_context, changes = nil )
      self.class.new(@name, @type).acquire_for(new_context)
   end
         
   def root_tuple()
      context.root_tuple
   end
   
   def attribute_path()
      path.slice(root_tuple.path.length..-1) 
   end

   def print_to( printer, width = nil )
      super
   end
   
   def writable?()
      false
   end
   
   def required?()
      writable?()
   end
   
   def derived?()
      false
   end
   
end # Attribute
end # Model
end # Schemaform


Dir[Schemaform.locate("attribute_types/*.rb")].each {|path| require path}

