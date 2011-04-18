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
# A specialized, non-base type that wraps constraints around another type.

module Schemaform
module Definitions
class ConstrainedType < Type

   def initialize( underlying_type, constraints, default = nil )
      super( underlying_type.schema )
      @underlying_type = underlying_type
      @constraints     = constraints
      @default         = default
   end
   
   def path()
      return @underlying_type.path if @path.nil? && @name.nil?
      return super
   end
   
   def self.build( underlying_type, modifiers, default = nil )
      constraints = []
      modifiers.each do |name, value|
         if constraint = underlying_type.schema.build_constraint(name, value, underlying_type) then
            constraints << constraint
         end
      end
      
      constraints.empty? ? underlying_type : new( underlying_type, constraints, default )      
   end
   
   def default()
      return @default unless @default.nil?
      return @underlying_type.resolve(TypeInfo::SCALAR).default
   end
   
   def type_info()
      @underlying_type.type_info
   end
   
   def method_missing( symbol, *args, &block )
      @underlying_type.send( symbol, *args, &block )
   end
   
   def resolve( relation_types_as = :reference )
      @underlying_type.resolve( relation_types_as )
   end

   def description()
      resolve().description()
   end
   
   def each_constraint( &block )
      @constraints.each do |constraint|
         yield( constraint )
      end
      
      @underlying_type.resolve().each_constraint( &block )
   end
   
   

end # ConstrainedType
end # Definitions
end # Schemaform