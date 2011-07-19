#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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

require Schemaform.locate("element.rb")
require Schemaform.locate("type.rb")


#
# A description of a single tuple (or "record") of data.  

module Schemaform
class Schema
class Tuple < Element

   def initialize( context, name = nil, registry_chain = nil )
      super(context, name)

      @type = StructuredType.new(:context => self) do |name|
         name.nil? ? @attributes.names : @attributes[name].type
      end

      @attributes = Registry.new(self, "an attribute" , registry_chain)
      @tuples     = Registry.new(self, "a child tuple")
      @expression = nil
   end
   
   def validate()
      return if @validated
      @validated = true
      @attributes.each{|attribute| attribute.validate()}
   end
   
   attr_reader :attributes, :tuples, :type
   
   def []( name )
      @attributes[name]
   end
   
   def names()
      @attributes.names
   end
   
   def each(&block)
      @attributes.each(&block)
   end
   
   def attribute?( name )
      @attributes.member?(name)
   end   
   
   alias member? attribute?
   
   def empty?()
      @attributes.empty? && @tuples.empty?
   end
   
   def register( attribute )
      type_check(:attribute, attribute, Attribute)
      @attributes.register(attribute)
   end
   
   def rename( from, to )
      @attributes.rename(from, to)
   end
   
   def register_tuple( tuple )
      @tuples.register(tuple)
   end
   
   def default()
      return @default unless @default.nil?
      @default = {}.tap do |pairs|
         @attributes.each do |name, attribute|
            if attribute.writable? then
               pairs[attribute.name] = attribute.resolve.default
            end
         end
      end
   end
   
   def description()
      (name.to_s != "" ? name.to_s : "") +  @type.description
   end
   
   def width()
      @attributes.length
   end   
   
   def recreate_in( new_context, changes = nil )
      self.new(new_context).tap do |tuple|
         recreate_children_in(tuple, changes)
      end      
   end
   
   def project(*names)
      Tuple.new(schema).tap do |projection|
         names.each do |name|
            check{ assert(@attributes.member?(name), "no such attribute [#{name}]") }
            if @attributes.member?(name) then
               projection.register @attributes[name]
            end
         end
      end
   end
   
   def describe( indent = "", name_override = nil, suffix = nil )
      super
      child_indent = indent + "   "
      @attributes.each do |attribute|
         attribute.describe(child_indent)
      end
   end
   
      
   
   
   
   # ==========================================================================================
   #                                       Type Operations
   # ==========================================================================================

   def dereference( lh_expression, rh_symbol )
      if @attributes.member?(rh_symbol) then
         Productions::DottedExpression.new(lh_expression, rh_symbol, @attributes[rh_symbol].type) 
      else
         nil
      end
   end
   
   
   # 
   # Recreates our individual attributes in the new tuple. If changes are present, they may contain 
   # replacements for attributes, including (possibly) changes to whole subtuples. We proceed by 
   # merging them together. The changes are assumed to be partial, and can contain replacements and 
   # additions only. Anything not explicitly in the change structure is copied verbatim. Note that,
   # if a change replaces a Scalar (or anything else) with a Tuple, the master copy switches from 
   # us to the change.

   def recreate_children_in( new_context, changes = nil )
      if changes.nil? then
         @attributes.each do |attribute|
            new_context.register attribute.recreate_in(new_context)
         end
         @tuples.each do |tuple|
            new_context.register_tuple tuple.recreate_in(new_context)
         end
      else
         fail_todo "import of nested tuples with changes"
         
         (@attributes.names + changes.names).uniq.each do |name|
            if changes.member?(name) then
               if changes[name].definition.is_a?(Tuple) && @attributes.member?(name) && @attributes[name].definition.is_a?(Tuple) then
                  new_tuple = Tuple.new(tuple, name)
                  tuple.register changes[name].class.new(name, tuple, new_tuple)
                  @attributes[name].definition.recreate_children_in(new_tuple, changes[name].definition)
               else
                  tuple.register changes[name].recreate_in(tuple)
               end
            else
               tuple.register @attributes[name].recreate_in(tuple)
            end
         end
      end
   end
   
   
   
   
   

end # Tuple
end # Schema
end # Schemaform

