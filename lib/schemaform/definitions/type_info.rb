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
   def initialize( has_heading, is_multi_valued )
      @has_heading     = has_heading
      @is_multi_valued = is_multi_valued
   end

public
   SCALAR   = new( false, false )
   TUPLE    = new( true , false )
   SET      = new( false, true  )
   RELATION = new( true , true  )
   
   def has_heading?()
      @has_heading
   end
   
   def multi_valued?()
      @is_multi_valued
   end
   
   def single_valued?()
      !@is_multi_valued
   end
   
   def ===( type )
      info = type.respond_to?(:has_heading?) ? type : type.type_info
      @has_heading == info.has_heading? && @is_multi_valued == info.multi_valued?
   end

   def specialize( prefix = nil, suffix = nil )
      version = case self
      when SCALAR   ; "scalar"
      when TUPLE    ; "tuple"
      when SET      ; "set"
      when RELATION ; "relation"
      else
         fail
      end
      
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