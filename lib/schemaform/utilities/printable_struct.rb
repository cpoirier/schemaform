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
# A Printer-compatible Struct lookalike.

module Schemaform
class PrintableStruct
   include QualityAssurance
   
   #
   # Defines a class that takes a standard parameter list and provides retrievers to access them.

   def self.define( *parameters )
      Class.new(self) do
         @@defined_subclass_field_lists[self] = parameters
         
         define_method(:initialize) do |*values|
            fields.each{|name| instance_variable_set("@#{name}".intern, values.shift)}
         end

         parameters.each do |name|
            attr_reader "#{name}".intern
         end
      end         
   end
   
   #
   # Returns the list of field names.
   
   def fields()
      @@defined_subclass_field_lists[self.class]
   end
   
   #
   # Calls your block for each field name and value combination.
   
   def each()
      fields.each do |name|
         yield(name, instance_variable_get("@#{name}".intern))
      end
   end
   
   #
   # Returns a description of this object.
   
   def description()
      self.class.unqualified_name
   end

   #
   # Prints the object.
   
   def print_to( printer, top = true )
      printer.label(top ? self.class.unqualified_name : nil) do
         width = fields.collect{|n| n.to_s.length}.max()
         each do |name, value|
            printer.label(name.to_s.ljust(width)){ printer.print(value) }
         end
      end
   end
   
   @@defined_subclass_field_lists = {}
      
end # PrintableStruct
end # Schemaform