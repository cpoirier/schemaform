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
   
   def type()
      fail_unless_overridden(self, :type)
   end
   
   def writable?()
      false
   end
   
   def optional?()
      false
   end
   
   def recreate_in( tuple )
      fail_unless_overridden(self, :recreate_in)
   end
   
   
   
   # ==========================================================================================
   #                                           Conversion
   # ==========================================================================================

   #
   # Lays out the attribute into database primitives. Generally, subclasses should extend, not
   # override this routine, as it will create a Layout::Group for you to handle your naming.
   
   def lay_out( into )
      into.define_group(self.name)
   end
   
   def lay_out_tuple( tuple, into )
      tuple.each_attribute do |attribute|
         attribute.lay_out(into)
      end
   end
   
   def lay_out_set( set, into )
      subtable = into.define_table(self.name)
      send_specialized :lay_out, set.member_definition, subtable
   end
   
   def lay_out_list( list, into )
      subtable = into.define_table(self.name)
      into.define_field(:__first, schema.identifier_type, subtable.id_field)
      into.define_field(:__last , schema.identifier_type, subtable.id_field)
   end
   
   def lay_out_type( type, into )
      into.define_field(:__value, type)
   end
   
end # Attribute
end # Definitions
end # Schemaform


Dir[Schemaform.locate("attribute_types/*.rb")].each {|path| require path}
