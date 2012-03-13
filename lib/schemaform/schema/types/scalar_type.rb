#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
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
# Base class for scalar types.

module Schemaform
class Schema
class ScalarType < Type
   
   #
   # Additional attributes include:
   #  :loader => a Proc that converts data from disk into a memory representation (Object)
   #  :storer => a Proc that converts object into data for storage on disk
   
   def initialize( attrs )
      super
      @loader = attrs.fetch(:load , @base_type && @base_type.scalar_type? ? @base_type.loader : nil)  # Copied locally for convenience
      @storer = attrs.fetch(:store, @base_type && @base_type.scalar_type? ? @base_type.storer : nil)  # Copied locally for convenience      
   end
   
   attr_reader :loader, :storer
   
   def scalar_type?
      true
   end
   
   def simple_type?()
      true
   end
   
   def description()
      return name.to_s if name
      return @base_type.description if @base_type.exists?
      return super
   end
   
   
   #
   # Instructs the type to produce a memory representation of a stored value.
   
   def load( stored_value )
      if @storer then
         @storer.responds_to?(:call) ? @storer.call(value) : @storer 
      else
         stored_value
      end
   end
   
   
   #
   # Instructs the type to produce a storable value from a memory representation.
   
   def store( memory_value )
      if @loader then
         @loader.responds_to?(:call) ? @loader.call(stored_value) : @loader
      else
         memory_value
      end
   end
   
   
   
   

end # ScalarType
end # Schema
end # Schemaform