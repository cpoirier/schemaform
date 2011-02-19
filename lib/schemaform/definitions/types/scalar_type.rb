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
# The base type for all scalar types.  Scalar types follow a type hierarchy for assignment and 
# join compatibility, and can have a set of TypeConstraints that limit the domain of the 
# underlying data type.

module Schemaform
module Definitions
class ScalarType < Type

   #
   # If you specify a Schema, it will be used.  If not, it will be pulled from the base Type.
   
   def initialize( base_type = nil, schema = nil, name = nil )
      super( schema || base_type.schema, name )
      warn_once( "ScalarType.new() interface seems wrong" )
      @base_type = base_type
   end
   
   def type_info()
      TypeInfo::SCALAR
   end
   
   def description()
      return name.to_s if named?
      return "hi"
      return @base_type.resolve.description if @base_type.exists? && @base_type.is_a?(Type)
      return super
   end

   def base_type()
      @base_type.nil? ? nil : @base_type.resolve()
   end
   
   def complete?()
      return storage_type.exists? && mapped_type.exists?
   end
   
      
   def resolve()
      self
   end
   
   
   #
   # Returns the underlying StorableType for this Type, or nil.
   
   def storage_type()
      if !defined?(@storage_type) then
         @storage_type = @base_type.nil? ? nil : @base_type.resolve.storage_type
      end
      
      return @storage_type
   end
   
   #
   # Returns the underlying MappedType for this Type, or nil.
   
   def mapped_type()
      if !defined?(@mapped_type) then
         @mapped_type = @base_type.nil? ? nil : @base_type.resolve.mapped_type
      end
   
      return @mapped_type
   end
   
   
   # 
   # Returns true IFF the specified value is an instance of this Type.
   
   def accepts?( value )
      return false if @base_type.nil?
      return false unless @base_type.accepts?(value)
      @constraints.each do |constraint|
         return false unless constraint.accepts?( value )
      end
      
      return true
   end
   
   
   #
   # Returns true if a value of this type can be compared to a value of the other.
   
   def comparable_to?( other )
      return true if storage_type.exists? && storage_type == other.storage_type
      return true if assignable_from?( other )
      return other.assignable_from?( self )
   end
   
   #
   # Returns true if a variable of this type can accept a value of the other.
   
   def assignable_from?( source )
      return source.typeof?(self)
   end
   
   #
   # Returns true if this type is a direct descendent of the other type.
   
   def typeof?( other )
      return true if other == self

      current = self
      while current = current.base_type
         return true if other == current
      end
      
      return false
   end
   
   #
   # Iterates over this class and every base type.
   
   def each_effective_type()
      current = self
      while current
         yield( current )
         current = current.base_type
         current = current.resolve if current
      end
   end
   
   
   #
   # Calls your block once for each constraint.  Pass a name to restrict.
   
   def each_constraint( &block )
      @base_type.resolve.each_constraint( &block ) if @base_type
   end
   
   
   

end # ScalarType
end # Definitions
end # Schemaform

Dir[Schemaform.locate("scalar_types/*.rb")].each {|path| require path}
