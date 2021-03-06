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

require Schemaform.locate("component.rb")


#
# Base class for the typing system. Unlike Ruby, database are strongly typed, and need to 
# be (in order to layout and pre-allocate storage). This class provides the basis of the 
# Schemaform typing system, which must bridge between the two worlds.
#
# Important operations include +join_compatible?+ and +assignable_from?+, which are used
# to determine type compatibility of expressions.

module Schemaform
module Model
class Type < Component
   
   #
   # Extracts :check and :check_* entries from a set of constraints, returning an array of
   # check constraints (Procs, generally).

   def self.build_checks( constraints )
      used_keys = []
      checks    = []
      
      constraints.delete_if do |key, value|
         if name.to_s =~ /^check(_|$)/ then
            checks << value
            true
         else
            false
         end
      end

      checks
   end



   # ==========================================================================================


   #
   # Validates a value that is supposed to be of this type. Raises an exception if a problem
   # is discovered.
   
   def validate( value )
      @base_type ? @base_type.validate(internalize(value)) : true
   end
   
   #
   # Converts a value into the internal format of this type, applying any specified :storer.
   
   def internalize( value )
      value
   end
   
   #
   # Converts a value from the internal format of this type, by applying any :loader routines.
   
   def externalize( value )
      value
   end

   
   
   
   # ==========================================================================================
   
   attr_reader :base_type, :default
   
   def scalar_type?     ; false ; end
   def collection_type? ; false ; end
   def naming_type?     ; false ; end
   def simple_type?     ; false ; end
   def unknown_type?    ; false ; end
   
   
   def type()
      self
   end
   
   def evaluated_type()
      self
   end
   
   def singular_type()
      self
   end
   
   def effective_type()
      self
   end
   
   def acquire_for( new_context )
      # types are always owned directly be the schema
   end
   
   #
   # Verifies that the Type.
   
   def verify()
      true
   end
   


   #
   # Returns an anonymous wrapper on this type with the supplied constraints.
   
   def constrain( constraints )
      return self if constraints.empty?
      
      constraints[:base_type] = self
      UserDefinedType.new(constraints)
   end


   #
   # Returns a human-readable summary of the type, for inclusion in diagnostic output.
   
   def description()
      return full_name.to_s if name
      return base_type.description if base_type
      return "an unnamed #{self.class.name.sub("Type", "").sub(/.*::/, "").identifier_case} type"
   end
   
   def print_to( printer )
      printer.print( description )
   end
   
   

   #
   # Attributes include:
   #  :name      => any name for this type
   #  :base_type => the base type for this type
   #  :default   => the default value for this type
   #  :loader    => a Proc that converts data from disk into a memory representation (Object)
   #  :storer    => a Proc that converts object into data for storage on disk
   
   def initialize( attrs )
      super(attrs.fetch(:name, nil))

      @base_type = attrs.fetch(:base_type, nil)
      @default   = attrs.fetch(:default, @base_type ? @base_type.default : nil)  # Copied locally for convenience
      @checks    = self.class.build_checks(attrs)         
   end


   #
   # Returns a specific type by applying any supported modifiers to this (presumbly general) one. 
   # Used by Schema.build_type() to allow types to handle dimensions and other similar modifiers. If 
   # you don't support any modifiers, simply return self. Consume any modifiers you do use.
   
   def make_specific( modifiers )
      self
   end
   
   
   #
   # Returns true if this and the other type can be joined.
   
   def join_compatible?( with )
      return nil if unknown_type? || with.unknown_type?
      return true if assignable_from?(with)
      return with.assignable_from?(self)
   end
   
   #
   # Returns true if a variable of this type can accept a value from a variable of the other
   # type.
   
   def assignable_from?( rh_type )
      unknown_type? || rh_type.unknown_type? ? false : rh_type.descendent_of?(self)
   end
   
   
   #
   # Returns true if this type descends from the other.
   
   def descendent_of?( base_type )
      current = self
      until current.nil?
         return true if base_type == current
         current = current.base_type
      end
      false
   end
   
   alias typeof? descendent_of?
   
   
   #
   # Returns true if the other type descends from this one.
   
   def ancestor_of?( descendent_type )
      return descendent_type.descendent_of?(self)
   end
   
   def pedigree()
      if block_given? then
         if @pedigree.exists? then
            @pedigree.each do |type|
               result = yield(type)
            end
         else
            current = self
            until current.nil?
               result  = yield(current)
               current = current.base_type
            end
         end
         return result
      else
         unless @pedigree.exists?
            @pedigree = [self]
            current = self.base_type
            until current.nil?
               @pedigree << current
               current = current.base_type
            end
         end

         return @pedigree
      end
   end
   
   #
   # Return the best common type that can hold both this type and the 
   # rhs_type. Some examples:
   #   text(20) + text(10) = text(20)
   #   list(relation(X)) + list(relation(Y)) = list(relation)
   #   text(20) + list(text(20)) = any

   def best_common_type( rhs_type )

      #
      # Short cut the hard work, if the answer is obvious . . . 

      return self     if rhs_type.nil?
      return rhs_type if unknown_type?
      return self     if rhs_type.unknown_type?
      return self     if assignable_from?(rhs_type)
      return rhs_type if rhs_type.assignable_from?(self)
      
      
      #
      # If we are going to have to do the work, search each pedigree
      # for a member that is assignable from the other side.
      
      if base_type.nil? || rhs_type.base_type.nil? then
         return self.class.new() if self.class == rhs_type.class || self.is_a?(rhs_type.class)
         return rhs_type.class.new() if rhs_type.is_a?(self.class)
         return schema.unknown_type()
      else
         lhs_common = nil
         pedigree() do |type|
            if type.assignable_from?( rhs_type ) then
               lhs_common = type
               break
            end
         end

         rhs_common = nil
         rhs_type.pedigree do |type|
            if type.assignable_from?( self ) then
               rhs_common = type
               break
            end
         end
         
         return schema.unknown_type if lhs_common.nil? && rhs_common.nil?
         return rhs_common if lhs_common.nil?
         return lhs_common if rhs_common.nil?

         #
         # If we have a choice, pick the *most* specific of the two.

         return lhs_common if rhs_common.assignable_from?(lhs_common)
         return rhs_common
      end
   end
   
   
   def ==( rh_type )
      return true if rh_type.name == name
      return true if (!!rh_type.name ^ !!name) && rh_type.class == self.class
      return false
   end
   

end # Type
end # Model
end # Schemaform


Dir[Schemaform.locate("types/*.rb")].each do |path|
   require path
end
