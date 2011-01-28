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
class Definition
   include QualityAssurance

   def initialize( context, name = nil )
      @context = context
      @name    = name
   end

   attr_reader :context
   
   def schema()
      if @schema.nil? then
         @schema = self.is_a?(Definitions::Schema) ? self : context.schema
         self.name = @name if @name
      end
      @schema
   end
   
   def path()
      return @path if defined?(@path) && @path.exists?
      return @context.path if @context.exists?
      return nil
   end
   
   def path=( path )
      @path = path.flatten
   end
   
   def name=( name )
      self.path = context.nil? ? [name] : [context.path, name]
   end
   
   def name()
      return nil if path.nil? || path.empty?
      return path.last
   end
      
   def full_name()
      return nil if path.nil?
      return path.join(".")
   end
   
   def named?()
      !name().nil?
   end
   
   def root()
      schema.context ? schema.context.root : schema
   end
   


end # Definition
end # Schemaform


Dir[Schemaform.locate("definitions/*.rb")].each do |path| 
   require path
end
