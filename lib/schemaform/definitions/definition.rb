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
class Definition
   include QualityAssurance

   def initialize( context, name = nil )
      @context = context
      @name    = name
      @path    = nil     # Defer path creation until needed, as some objects are created in the constructors of their contexts . . . . 
   end

   attr_reader :context

   def schema()
      self.is_a?(Definitions::Schema) ? self : context.schema
   end
   
   def path()
      if @path.nil? then
         case @name
         when Symbol, String, Class
            @path = (context.nil? ? [] : context.path) + [@name]
         when FalseClass
            @path = context.path
         else
            fail( "name has not been set for object of class [#{self.class.name}]" + (@context ? " in #{@context.full_name}]" : "") )
         end
      end
      
      return @path
   end
   
   def path=( path )
      @path = path.flatten
   end
   
   def name=( name )
      if @path then
         path = [self.path.slice(0..-2), name]
      else
         @name = name
      end
   end
   
   def name()
      return path.last
   end
      
   def full_name()
      return nil if path.nil?
      return path.join(".")
   end
   
   def named?()
      @name || @path
   end
   
   def root()
      schema.context ? schema.context.root : schema
   end
   
   def to_s()
      full_name()
   end

   def supervisor()
      schema.supervisor()
   end
   
end # Definition
end # Definitions
end # Schemaform

