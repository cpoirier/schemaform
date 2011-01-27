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
# A base class for elements of the Schema, providing a route back.  Also deals with standard
# naming, for things that need it.

module Schemaform
module Definitions
class Base
   include QualityAssurance

   def initialize( schema, name = nil, allow_nil_schema = false )
      type_check( :schema, schema, Schema, allow_nil_schema )
      @schema = schema
      self.name = name if name
   end

   attr_reader :schema, :path
   
   def parent()
      @schema
   end
   
   def path=( path )
      @path = path.flatten
   end
   
   def name=( name )
      self.path = parent().nil? ? [name] : [parent().path, name]
   end
   
   def name()
      return nil if !defined?(@path) || @path.nil? || @path.empty?
      return @path.last
   end
      
   def full_name()
      return nil if !defined?(@path) || @path.nil?
      return @path.join(".")
   end
   
   def named?()
      !name().nil?
   end
   


end # Base
end # Definitions
end # Schemaform