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


module Schemaform
module Definitions

   
class Schema < Definition
   def lay_out()
      if @layout.nil? then
         @layout = Layout::SQL::Schema.new(self)
         @entities.each do |entity|
            entity.lay_out( @layout )
         end
      end

      @layout
   end
end

class Entity < Relation
   def lay_out( into )
      table = into.define_table(name)
      @heading.each_attribute do |attribute|
         attribute.lay_out(table)
      end
   end
end

   

class Attribute < Definition
   
   #
   # Lays out the attribute into database primitives. Generally, subclasses should extend, not
   # override this routine, as it will create a Layout::Group for you to handle your naming.

   def lay_out( into )
      into.define_group(self.name).tap do |group|
         send_specialized(:lay_out, @definition, group)
      end
   end
   
   def lay_out_scalar( scalar, into )
      send_specialized(:lay_out, scalar.type, into)
   end

   def lay_out_formula( formula, into )
      send_specialized(:lay_out, formula.type, into)
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

end


class OptionalAttribute < WritableAttribute
   def lay_out( into )
      group = super(into)
      group.define_field(:__present, schema.boolean_type)
   end   
end 


class VolatileAttribute < DerivedAttribute
   def lay_out( into )
   end
end 



end # Definitions
end # Schemaform


["sql"].each do |directory|
   Dir[Schemaform.locate("#{directory}/*.rb")].each do |path|
      require path
   end
end
