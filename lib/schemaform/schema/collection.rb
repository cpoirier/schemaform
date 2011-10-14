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

require Schemaform.locate("element.rb")


#
# Base class for collection elements.

module Schemaform
class Schema
class Collection < Element
   
   def self.type_class()
      fail_unless_overridden self, :type_class
   end
   
   def self.tuple_collection_name()
      nil
   end
   
   def initialize( member, context = nil )
      super(context || member.context, self.class.type_class.build(member.type))
      @member = member
   end
   
   attr_reader :member
   
   def has_attributes?()
      @member.has_attributes?()
   end
   
   def attribute?( name )
      @member.attribute?(name)
   end
   
   def print_to( printer, name_override = nil )
      if has_attributes? && (override = self.class.tuple_collection_name) then
         name_override ||= member.name
         label = "#{override} of"
         label += " #{name_override}" if name_override
         printer.label(label, "") do
            @member.print_attributes_to(printer)
         end
      else
         printer.label("#{self.class.unqualified_name} of", "") do
            @member.print_to(printer)
         end
      end
   end


end # Collection
end # Schema
end # Schemaform

