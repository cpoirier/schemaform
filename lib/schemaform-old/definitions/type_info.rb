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
# Provides internal meta-type information.

module Schemaform
module Definitions
class TypeInfo
   
private
   def initialize( has_heading, order )
      @has_heading = has_heading
      @order       = order
   end

public
   REFERENCE   = new( nil  , 0 )
   SCALAR      = new( false, 0 )
   SET         = new( false, 1 )
   SEQUENCE    = new( false, 2 ) 
   TUPLE       = new( true , 0 )
   RELATION    = new( true , 1 )
   ENUMERATION = new( true , 2 )   # Could be "list", but I like that the most complex type has the longest name.
   
   def reference?()
      @has_heading.nil? && @order == 0
   end
   
   def has_heading?()
      @has_heading
   end
   
   def ordered?()
      @order == 2
   end
   
   def multi_valued?()
      @order > 0
   end
   
   def single_valued?()
      @order == 0
   end
   
   def reference?()   ; self == REFERENCE   ; end
   def scalar?()      ; self == SCALAR      ; end
   def set?()         ; self == SET         ; end
   def sequence?()    ; self == SEQUENCE    ; end
   def tuple?()       ; self == TUPLE       ; end
   def relation?()    ; self == RELATION    ; end
   def enumeration?() ; self == ENUMERATION ; end

   
   def ===( type )
      return false if type.nil?
      info = type.respond_to?(:has_heading?) ? type : type.type_info
      return reference? && info.reference? if reference? || info.reference?
      @has_heading == info.has_heading? && multi_valued? == info.multi_valued? && ordered? == info.ordered?
   end
   
   def to_s()
      case self
      when REFERENCE   ; "reference"
      when SCALAR      ; "scalar"
      when SET         ; "set"
      when SEQUENCE    ; "sequence"
      when TUPLE       ; "tuple"
      when RELATION    ; "relation"
      when ENUMERATION ; "enumeration"
      else
         fail
      end
   end

   def specialize( prefix = nil, suffix = nil )
      version = to_s
      
      name = if suffix and prefix then
         format( "%s_%s_%s", prefix, version, suffix )
      elsif prefix
         format( "%s_%s", prefix, version )
      else
         format( "%s_%s", version, suffix )
      end
      
      name.intern
   end
   


end # TypeInfo
end # Definitions
end # Schemaform