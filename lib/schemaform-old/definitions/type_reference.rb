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
# A structure that captures a by-name reference to a Type or other type-like structure, with 
# some set of modifiers. When the time comes, the

module Schemaform
module Definitions
class TypeReference < Definition
   extend QualityAssurance
   
   def self.build( context, type_name, modifiers = {} )
      case type_name
      when Type, TypeReference
         check do
            assert( modifiers.empty?, "modifiers cannot be added to an existing Type or TypeReference" )
         end
         
         return type_name if Type === type_name
         return new( context, type_name.type_name, type_name.modifiers )
      else
         return new( context, type_name, modifiers )
      end
   end
   
   attr_reader :type_name, :modifiers, :restriction

   def initialize( context, type_name, modifiers = {} )
      type_check( :type_name, type_name, [Symbol, Class, Type] )
      super( context, type_name )
      @type_name   = type_name
      @modifiers   = modifiers
      @type        = nil
   end
   
   def resolve( relation_types_as = :reference )
      supervisor.monitor( self, false ) do
         ConstrainedType.build( schema.find_type(@type_name).resolve(relation_types_as), @modifiers, @modifiers.fetch(:default, nil) )
      end
   end

end # TypeReference
end # Definitions
end # Schemaform