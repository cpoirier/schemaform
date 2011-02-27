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
# A Attribute in a Tuple.

module Schemaform
module Definitions
class Attribute < Definition
   def initialize( tuple )
      type_check( :tuple, tuple, Tuple )
      super( tuple )
      @expression = Expressions::Attribute.new(self)
   end
   
   attr_reader :expression
   
   alias tuple context
   
   def root_tuple()
      tuple.root_tuple
   end
   
   def resolve( preferred = nil )
      fail_unless_overridden( self, :resolve )
   end
   
   def required?()
      false
   end
   
   def derived?()
      false
   end
   
   def optional?()
      false
   end
   
   
   
   # ==========================================================================================
   #                                           Conversion
   # ==========================================================================================

   
   def lay_out( builder )
      attribute_type = attribute.resolve()
      send( attribute_type.type_info.specialize("lay_out", "type"), builder, attribute_type )
   end

protected

   def lay_out_scalar_type( builder, attribute_type )
      fail_unless_overridden
   end
   
   
   def lay_out_set_type( builder, attribute_type )
      fail_unless_overridden
   end
   
   
   def lay_out_tuple_type( builder, attribute_type )
      fail_unless_overridden
   end
   
   
   def lay_out_relation_type( builder, attribute_type )
      fail_unless_overridden
   end
   
end # Attribute
end # Definitions
end # Schemaform


Dir[Schemaform.locate("attribute_types/*.rb")].each {|path| require path}
