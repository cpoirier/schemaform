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


require Schemaform.locate("derived_attribute.rb")


#
# A derived attribute that is kept always up to date in the database.

module Schemaform
module Definitions
class MaintainedAttribute < DerivedAttribute

   def initialize( tuple, block )
      super( tuple, block )
   end
   
   

protected

   # ==========================================================================================
   #                                           Conversion
   # ==========================================================================================


   #
   # Required scalar attributes are easy to convert.  In the Table, there will be a single
   # field.  In the TupleClass, we will be adding an accessor.
   
   def lay_out_scalar_type( builder, attribute_type )
      builder.define_field( name, attribute_type, false )
      builder.define_tuple_reader( name, attribute_type )
      builder.define_tuple_writer( name, attribute_type )
   end
   
   
   # 
   # Required tuple attributes are also easy to convert.  We just add the attribute name to 
   # the prefix and recurse.  
   
   def lay_out_tuple_type( builder, attribute_type )
      attribute_type.lay_out( builder )
   end
   
   
   #
   # Required set attributes require a subtable.  However, at least the member type is always a scalar.
   
   def lay_out_set_type( tuple_class, table, field_prefix, attribute_type, &custom_processing )
      member_type = attribute_type.member_type.resolve(TypeInfo::SCALAR)
      
      builder.define_tuple_reader( name, attribute_type )
      builder.define_tuple_writer( name, attribute_type )
      
      builder.define_table( name ) do
         if member_type.has_heading? then
            
            #
            # We don't want to build a new TupleClass in this case, so we will have to lay out the
            # TupleType attributes directly.
            
            builder.with_name( "referenced_" + member_type.context.context.heading.name ) do # The referenced Entity's TupleType name
               member_type.each_attribute do |attribute|
                  attribute.lay_out( builder )
               end
            end
         else
            builder.define_field( "member_value", member_type )
         end
      end
   end


end # MaintainedAttribute
end # Definitions
end # Schemaform