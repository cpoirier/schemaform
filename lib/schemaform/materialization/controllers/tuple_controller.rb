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
# A wrapper on a Schema-defined Tuple that provides services to a runtime Tuple class. 

module Schemaform
module Materials
class TupleController < Controller

   
   #
   # Defines a subclass into some container.

   def self.define( name, into )
      define_subclass(name, into) do
         @@defaults = {}
         
         def self.default_for( name, tuple = nil )
            return nil unless @@defaults.member?(name)
            default = @@defaults[name]
            default.is_a?(Proc) ? default.call(tuple) : default
         end
         
         def self.load( name, tuple )
            self.default_for(name, tuple)
         end
         
      end
   end


   #
   # Defines an attribute reader for the specified name.

   def self.define_attribute_reader( name, &preamble )
      define_instance_method( name, preamble ) do
         @attributes[name] || self.class.load(name, self)
      end
   end


   #
   # Defines an attribute writer for the specified name

   def self.define_attribute_writer( name, &preamble )
      define_instance_method( "#{name.to_s}=", preamble ) do |value|
         @dirty = true
         @attributes[name] = value
      end
   end


   #
   # Defines a default value (or value-producing Proc) for an attribute. This is
   # used if the value is not defined when the Tuple is instantiated.

   def self.define_attribute_default( name, value )
      class_eval( "@@defaults[name] = value" )
   end



   def initialize( attributes = {} )
      @attributes = attributes
      @dirty      = false
   end
   
   def present?( name )
      !@attributes.fetch(name, nil).nil?
   end
   
   def dirty?()
      @dirty
   end

   warn_once( "TODO: apply on_demand and defaults policies to accessors" )


end # TupleController
end # Materials
end # Schemaform