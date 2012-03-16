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


#
# Base class for container types.

module Schemaform
module Model
class CollectionType < Type

   attr_reader :member_type

   def self.build( member_type, attrs = {} )
      attrs[:member_type] = member_type
      new(attrs)
   end
   
   def initialize( attrs = {} )
      @member_type = attrs.fetch(:member_type, nil) || schema.unknown_type
      super(attrs)
   end
   
   def generic?()
      @member_type == schema.unknown_type()
   end
   
   def naming_type?
      @member_type.naming_type?
   end
   
   def collection_type?()
      true
   end
   
   def attribute?( attribute_name )
      naming_type? && @member_type.attribute?(attribute_name)
   end
   
   def singular_type()
      @member_type.singular_type()
   end
   
   def best_common_type( rhs_type )
      common_type = super( rhs_type )

      #
      # If common_type is parameterized, then both types are parameterized
      # and generally compatible, so we should try finding the best common 
      # type for the parameters, too.

      if common_type.is_a?(self.class) then
         common_member_type = @member_type.best_common_type(rhs_type.member_type)
         
         if common_member_type.unknown_type? then
            return common_type
         else
            return self.class.new(:member_type => common_member_type)
         end
      else
         return common_type
      end
   end

   def print_to( printer, label = nil )
      printer.label(label || type_description, "") do
         @member_type.print_to(printer)
      end
   end
   
   def type_description()
      @type_description ||= self.class.unqualified_name.identifier_case.sub(/_type$/, "") + "_of"
   end
   

end # CollectionType
end # Model
end # Schemaform