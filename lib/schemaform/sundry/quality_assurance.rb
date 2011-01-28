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
   # A mixin for Schemaform classes that provides a variety of quality-related routines.
   
   module QualityAssurance
      def self.included( calling_class )
         if !defined?(@@quality_assurance__checks_enabled) then
            @@quality_assurance__checks_enabled   = true
            @@quality_assurance__warnings_enabled = true
         end
      end


      # =======================================================================================
      #                                      Runtime Checks
      # =======================================================================================

      
      #
      # Provides a context in which interface contract enforcement and other quality code 
      # can be easily disabled at run-time.  If you pass in a value, it will be passed to
      # your block, and returned after (even if your block wasn't called).
      
      def check( value = nil )
         return value unless @@quality_assurance__checks_enabled
         yield( value )
         value
      end

      
      #
      # Verifies that object is (one) of the specified type(s).

      def type_check( name, object, type, allow_nil = false )
         return true unless @@quality_assurance__checks_enabled || check_even_if_checks_disabled
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
            message = message + ", found " + actual
            raise TypeCheckFailure.new( message )
         end

         return true
      end


      def self.disable_checks()
         @@quality_assurance__checks_enabled = false
      end
      
      def self.checks_disabled?()
         !@@quality_assurance__checks_enabled
      end
      


      # =======================================================================================
      #                                          Warnings
      # =======================================================================================

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
      
      
      def self.disable_warnings()
         @@quality_assurance__warnings_enabled = false
      end
      
      def self.warnings_disabled?()
         !@@quality_assurance__warnings_enabled
      end
      
      


      # =======================================================================================
      #                                       Assertions
      # =======================================================================================

      
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

      def fail_unless_overridden( object, method )
         method = object.instance_class.instance_method(method) unless method.is_a?(Method)
         fail( "You must override: #{method.owner.name}.#{method.name} in #{object.class.name}" )
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
      # Adds data to any Bug thrown within the block.  Note: annotations will not
      # overwrite existing data (which is probably what you want).
            
      def annotate_errors( data )
         begin
            yield()
         rescue Bug
            $!.annotate( data )
            raise
         end
      end



   end # QualityAssurance
   
   
   #
   # A base exception class for detected bugs.
   
   class Bug < ScriptError
      attr_reader :data

      def initialize( message, data = nil )
         super( message )
         @data = data
      end
      
      def annotate( additional_data )
         @data = additional_data.merge( @data || {} )
      end
      
      def print_data( stream = $stderr )         
         unless @data.nil? || @data.empty?
            width = @data.keys.inject(0){|max, current| width = current.to_s.length; width > max ? width : max }
            @data.each do |key, value|
               stream.puts( key.to_s.rjust(width) + ": " + value.to_s )
            end
         end
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
   
   def relative_backtrace( relative_to, skip_qa_routines = true )
      relative_to = File.expand_path(relative_to.sub(/\/$/, "")) + "/"

      relative_backtrace = []
      backtrace.each do |line|
         path, rest = line.split(":", 2)
         absolute_path = File.expand_path(path)
         
         if skip_qa_routines && absolute_path == __FILE__ && rest =~ /check|assert/ then
            relative_backtrace.clear
         else
            relative_backtrace << (absolute_path.start_with?(relative_to) ? absolute_path[(relative_to.length)..-1] : absolute_path) + ":" + rest
         end
      end
      
      relative_backtrace
   end
   
   def generate_report( stream = $stderr, backtrace_levels = 15 )
      if ENV.member?("TM_LINE_NUMBER") then 
         print_data( stream ) if respond_to?("print_data")
         raise
      else
         heading   = "CAUGHT #{self.class.name}"
         message   = failsafe_message
         backtrace = relative_backtrace(Schemaform.locate("schemaform/.."))
         
         stream.puts ("=" * message.length)
         stream.puts heading
         stream.puts message
         print_data( stream ) if respond_to?("print_data")
         stream.puts ""
         backtrace[0..(backtrace_levels - 1)].each{ |line| stream.puts "   #{line}" }
         stream.puts "   . . . skipping #{backtrace.length - backtrace_levels} more levels" if backtrace.length > backtrace_levels
         return 2
      end
   end
end
