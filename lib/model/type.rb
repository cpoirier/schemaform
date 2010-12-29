#!/usr/bin/env ruby -KU
# =============================================================================================
# SchemaForm
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
# Base class for all SchemaForm types.  Unlike Ruby, databases are (necessarily) rather strongly 
# typed, and the typing system provides a way to manage assignment and join compatibility,
# among other things.

module SchemaForm
module Model
class Type

   attr_reader :name, :base_type, :constraints
   
   def initialize( schema, name, base_type, constraints = [] )
      @schema      = schema
      @name        = name
      @base_type   = base_type  
      @constraints = constraints
   end 
   
   #
   # Returns the underlying StorableType for this Type, or nil.
   
   def storage_type()
      if !defined?(@storage_type) then
         @storage_type = @base_type.nil? ? nil : @base_type.storage_type
      end
      
      return @storage_type
   end
   
   #
   # Returns the underlying MappedType for this Type, or nil.
   
   def mapped_type()
      if !defined?(@mapped_type) then
         @mapped_type = @base_type.nil? ? nil : @base_type.mapped_type
      end
   
      return @mapped_type
   end
   
   
   #
   # Returns the complete set of constraints, collected from this an and all base types.
   
   def all_constraints()
      return @constraints if @base_type.nil?
      return @constraints + @base_type.all_constraints
   end
   
   
   # 
   # Returns true IFF the specified value is an instance of this Type.
   
   def accepts?( value )
      return false if @base_class.nil?
      return false unless @base_class.accepts?(value)
      @constraints.each do |constraint|
         return false unless constraint.accepts?( value )
      end
      
      return true
   end
   
   
   #
   # Returns true if this type can be stored in a typical database.
   
   def storable?()
      storage_type().exists? && mapped_type().exists?
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
      end
   end
   

end # Type
end # Model
end # SchemaForm


Dir[$schemaform.local_path("types/*.rb")].each {|path| require path}

