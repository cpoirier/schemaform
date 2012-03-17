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

require Schemaform.locate("element.rb")


#
# Base class for collection elements.

module Schemaform
module Model
class Collection < Element
   
   def self.type_class()
      fail_unless_overridden
   end
   
   def initialize( member, owner = nil )
      super(self.class.type_class.build(member.type))
      @member = member.acquire_for(self)
   end
   
   def add_typing_information( names )
      warn_todo("support for typing information")
   end
   
   attr_reader :member, :id, :owner

   def has_attributes?()
      @member.has_attributes?()
   end

   def attribute?( name )
      @member.attribute?(name)
   end
   
   def verify()
      @member.verify()
      super
   end
   
   def print_to( printer, name_override = nil )
      printer.label("#{self.class.unqualified_name} of", "") do
         print_body_to(printer)
      end
   end
   
   def print_body_to( printer )
      if @member.is_a?(Tuple) then
         @member.print_to(printer)
      else
         printer.indent do
            @member.print_to(printer)
         end
      end
   end


end # Collection
end # Model
end # Schemaform

