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


module Schemaform

   #
   # A base exception class for detected bugs.
   
   class Bug < ScriptError
      attr_reader :data

      def initialize( message, data = nil )
         super( message )
         @data = data
      end
   end

   class TerminatedForCause < Bug; end
   class AssertionFailure   < Bug; end
   class TypeCheckFailure   < Bug; end



   
   #
   # A mixin for Schemaform classes that provides a variety of quality-related routines.
   
   module Quality
      
      #
      # Raises an AssertionFailure if the condition is false.

      def assert( condition, message, data = nil )
         unless condition
            data = yield() if block_given?
            raise AssertionFailure.new(message, data)
         end
      end
      


      #
      # Raises a TerminatedForCause exception indicating something happened that shouldn't have.

      def terminate( description = nil, data = nil )
         if description.nil? then
            description = "Incomplete: " + caller()[0]
         end

         raise TerminatedForCause.new( description, data )
      end


      #
      # Dumps a message to $stderr, once per message.
      
      def warn_once( message )
         $schemaform_quality_warnings = {} if $schemaform_quality_warnings.nil?
         unless $schemaform_quality_warnings.member?(message)
            warn( message )
         end
      end
      
      
      #
      # Dumps a message to $stderr.
      
      def warn( message )
         $stderr.puts( (message =~ /^[A-Z]+: / ? "" : "WARNING: ") + message )
         $schemaform_quality_warnings = {} if $schemaform_quality_warnings.nil?
         $schemaform_quality_warnings[message] = true
      end
      

      #
      # Catches any exceptions raised in your block and returns error_return instead.  Returns
      # your block's return value otherwise.

      def ignore_errors( error_return = nil )
         begin
            return yield()
         rescue
            return error_return
         end
      end


      #
      # Verifies that object is (one) of the specified type(s).

      def type_check( object, type, allow_nil = false )
         return true if object.nil? && allow_nil

         message = ""
         error = true

         if type.kind_of?( Array ) then
            type.each do |t|
               if t.is_a?(String) then 
                  error = !(object.class.name == t)
               elsif object.kind_of?(t) then
                  error = false
                  break
               end
            end

            if error then
               names = type.collect {|t| t.name}
               message = "expected one of [ " + names.join( ", " ) + " ]"
            end
         else
            if type.is_a?(String) then
               error = !(object.class.name == type)
               message = "expected " + type if error
            elsif object.kind_of?(type) then
               error = false
            else
               message = "expected " + type.name
            end
         end

         if error then
            actual = object.class.name
            message = "unexpected type " + actual + " (" + message + ")"
            raise TypeCheckFailure.new( message )
         end

         return object
      end

   end # Quality
end # Schemaform




#
# Extra methods for the Ruby Exception class.

class Exception

   #
   # A version of message() that kills the current thread if message() hangs (which
   # it has often done, in the past).

   def failsafe_message()

      main_thread = Thread.current
      failsafe_thread = Thread.start do
         sleep 1
         main_thread.kill
      end

      value = message()
      failsafe_thread.kill

      return value
   end

end
