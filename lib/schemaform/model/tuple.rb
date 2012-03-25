#!/usr/bin/env ruby
# =============================================================================================
# Schemaform
# A DSL giving the power of spreadsheets in a relational setting.
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

require Schemaform.locate("element.rb")
require Schemaform.locate("attribute.rb")
require Schemaform.locate("type.rb")


#
# A description of a single tuple (or "record") of data.  

module Schemaform
module Model
class Tuple < Element

   def has_attributes?()
      true
   end
   
   def initialize( name = nil, registry_chain = nil )
      super(TupleType.new(self), name)
      
      @attributes = Registry.new(self, "an attribute" , registry_chain)
      @tuples     = Registry.new(self, "a child tuple")
   end
   
   def verify()
      unless @validated
         @validated = true         
         @attributes.each{|attribute| attribute.verify()}
      end
      @validated
   end
   
   attr_reader :attributes, :tuples
   
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
      @attributes.register(attribute.acquire_for(self))
   end
   
   def rename( from, to )
      @attributes.rename(from, to)
   end
   
   def register_tuple( tuple )
      @tuples.register(tuple)
   end
   
   def default()
      return @default unless @default.nil?
      @default = {}.use do |pairs|
         @attributes.each do |name, attribute|
            if attribute.writable? then
               pairs[attribute.name] = attribute.resolve.default
            end
         end
      end
   end
   
   def description()
      (name.to_s != "" ? name.to_s : "") + "{" + names.join(", ") + "}"
   end
   
   def width()
      @attributes.length
   end   
   
   def recreate_in( new_context, changes = nil )
      self.class.new(@name).acquire_for(new_context).use do |tuple|
         recreate_children_in(tuple, changes)
      end      
   end
   
   def project(*names)
      Tuple.new(schema).use do |projection|
         names.each do |name|
            check{ assert(@attributes.member?(name), "no such attribute [#{name}]") }
            if @attributes.member?(name) then
               projection.register @attributes[name]
            end
         end
      end
   end
   
   def print_to( printer, name_override = nil )
      super
      printer.indent do
         print_attributes_to(printer)
      end
   end
   
   def print_attributes_to( printer )
      class_width = @attributes.collect{|a| a.class.unqualified_name.to_s.length}.max
      name_width  = @attributes.collect{|a| a.name.to_s.length}.max
      
      @attributes.each do |attribute|
         printer.print("#{attribute.class.unqualified_name.to_s.ljust(class_width)} #{attribute.name.to_s.ljust(name_width)} ", false)
         attribute.type.print_to(printer)
      end
   end
   
   def root_tuple()
      @root_tuple ||= find_context(false, self){|context| context.is_a?(Tuple)}
   end
   
   def context_entity()
      @context_entity ||= find_context{|context| context.is_an?(Entity)}
   end
   
      
   
   
   
   # ==========================================================================================
   #                                       Type Operations
   # ==========================================================================================

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
end # Model
end # Schemaform


