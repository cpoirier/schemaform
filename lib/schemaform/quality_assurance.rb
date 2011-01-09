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

require File.expand_path(File.dirname(__FILE__) + "/quality_assurance/interface_contracts.rb")

module Schemaform

   #
   # A mixin for Schemaform classes that provides a variety of quality-related routines.
   
   module QualityAssurance
      def self.included( calling_class )
         unless calling_class.name == "Schemaform"
            calling_class.instance_eval do
               include InterfaceContracts
            end
         end
      end
      
      #
      # Provides a context in which interface contract enforcement and other quality code 
      # can be easily disabled at run-time.  
      
      def check()
         return unless @@quality_assurance__checks_enabled
         yield
      end

      
      #
      # Raises an AssertionFailure if the condition is false.

      def assert( condition, message, data = nil, &block )
         fail( message, data, &block ) unless condition
         true
      end
      
      
      #
      # Raises an AssertionFailure outright.
      
      def fail( message, data = nil, &block )
         data = block.call() if block
         raise AssertionFailure.new(message, data)
      end
      
      
      #
      # Raises an AssertionFailure indicating a method should have been overrided.

      def fail_unless_overridden()
         fail( "You must override: " + caller()[0] )
      end


      #
      # Dumps a message to $stderr, once per message.
      
      def warn_once( message )
         @@quality_assurance__warnings = {} if !defined?(@@quality_assurance__warnings)
         unless @@quality_assurance__warnings.member?(message)
            warn( message )
         end
      end
      
      
      #
      # Dumps a message to $stderr.
      
      def warn( message )
         $stderr.puts( (message =~ /^[A-Z]+: / ? "" : "WARNING: ") + message )
         @@quality_assurance__warnings = {} if !defined?(@@quality_assurance__warnings)
         @@quality_assurance__warnings[message] = true
      end
      

      #
      # Asserts that condition is true, but still outputs the message.
      
      def assert_and_warn_once( condition, message, data = nil, &block )
         assert( condition, message, data, &block )
         warn_once( message )
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

      def type_check( object, type, allow_nil = false, last = nil )
         name = nil
         if object.is_a?(String) then
            name      = object
            object    = type
            type      = allow_nil
            allow_nil = last
         end
         
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
            message += " for [#{name}]" if name
            actual  = object.class.name
            message = message + " (found " + actual + ")"
            raise TypeCheckFailure.new( message )
         end

         return true
      end


      #
      # Disables quality assurance checks.  Note that this is a global setting.
      
      def self.disable_checks()
         @@quality_assurance__checks_enabled = false
      end
      
      def self.checks_disabled?()
         !@@quality_assurance__checks_enabled
      end
      
      @@quality_assurance__checks_enabled = true
   

   end # QualityAssurance
   
   
   #
   # A base exception class for detected bugs.
   
   class Bug < ScriptError
      attr_reader :data

      def initialize( message, data = nil )
         super( message )
         @data = data
      end
   end

   class AssertionFailure < Bug; end
   class TypeCheckFailure < Bug; end


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
