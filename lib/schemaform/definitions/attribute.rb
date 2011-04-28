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

require Schemaform.locate("definition.rb")


#
# An Attribute in a TupleType.
#
# Scalar attributes 

module Schemaform
module Definitions
class Attribute < Definition
   
   def initialize( tuple )
      super(tuple)
   end

   alias tuple context
   
   def root_tuple()
      tuple.root_tuple
   end
   
   def resolve( relation_types_as = :reference )
      fail_unless_overridden( self, :resolve )
   end
   
   def writable?()
      false
   end
   
   def optional?()
      false
   end
   
   def recreate_in( tuple )
      fail_unless_overridden( self, :recreate_in )
   end
   
   
   # ==========================================================================================
   #                                           Conversion
   # ==========================================================================================

   def lay_out( into )
      
   end
   
protected

   attr_writer :type

   def lay_out_scalar_type( builder, attribute_type )
      fail_unless_overridden( self, :lay_out_scalar_type )
   end
   
   
   def lay_out_set_type( builder, attribute_type )
      fail_unless_overridden( self, :lay_out_set_type )
   end
   
   
   def lay_out_tuple_type( builder, attribute_type )
      fail_unless_overridden( self, :lay_out_tuple_type )
   end
   
   
   def lay_out_relation_type( builder, attribute_type )
      fail_unless_overridden( self, :lay_out_relation_type )
   end
   
end # Attribute
end # Definitions
end # Schemaform


Dir[Schemaform.locate("attribute_types/*.rb")].each {|path| require path}
