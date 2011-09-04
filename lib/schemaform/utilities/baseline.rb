#!/usr/bin/env ruby -KU
# =============================================================================================
# Baseline
# Ruby extensions and support classes for a better world.
#
# [Website]   http://github.com/cpoirier/baseline
# [Copyright] Copyright 2004-2011 Chris Poirier (this file)
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




# =============================================================================================
#                                    General Ruby Extensions
# =============================================================================================


#
# Returns the object-specific class, to which you can add methods.

if !Object.method_defined?(:instance_class) then
   class Object
      def instance_class()
         class << self ; self ; end
      end
   end
end

#
# Defines plurally-named synonyms for some singularly-named routines.

if !Object.method_defined?(:responds_to?) then
   class Object
      def responds_to?( symbol, include_private = false )
         respond_to?( symbol, include_private )
      end

      def is_an?(vowel_started_class)
         is_a?(vowel_started_class)
      end
   end
end


#
# Defines some antonyms for nil?

if !Object.method_defined?(:exists?) then
   class Object
      def exists?()
         true
      end
      
      def set?()
         exists?
      end
   end
   
   class NilClass
      def exists?()
         false
      end
   end
end


#
# Ensures all objects can be converted to arrays. Individual objects are converted to
# a list of one; nil is converted to an empty list.

if !NilClass.method_defined?(:to_array) then
   class NilClass
      def to_array()
         return []
      end
   end
end

if !Object.method_defined?(:to_array) then
   class Object
      def to_array()
         return [self]
      end
   end
end

if !Array.method_defined?(:to_array) then
   class Array
      alias to_array to_a
   end
end


#
# Ensures you can run each() on any object. Individual (non-Enumeration) objects will pass 
# themselves to the block; nil will never call the block.

if !NilClass.method_defined?(:each) then
   class NilClass
      def each()
      end
   end
end

if !Object.method_defined?(:each) then
   class Object
      def each()
         yield( self ) 
      end
   end
end
   

class ArrayHash < Hash
   def self.new()
      super do |hash, key|
         hash[key] = []
      end
   end
end




# =============================================================================================
#                                        Object Extensions
# =============================================================================================

class Object

   #===========================================================================================
   if !Object.method_defined?(:with_value) then
      
      #
      # Sets the named instance variable to a value, and enters the supplied block, passing
      # this object.  Restores the instance variable to its original value before returning.
      # Do not include the @ in the variable name.

      def with_value( name, value, &block )
         result   = nil
   
         name     = "@#{name.to_s}"
         previous = instance_variable_get( name )
         begin
            instance_variable_set( name, value )
            result = block.call( self )
         ensure
            instance_variable_set( name, previous )
         end
   
         result
      end
      
      #
      # Equivalent to with_value(), but accepts multiple name/value pairs.

      def with_values( pairs = {}, &block )
         result   = nil
         previous = {}
         begin
            pairs.each do |name, value|
               variable = "@#{name.to_s}"
               previous[name] = instance_variable_get( variable )
               instance_variable_set( variable, value )
            end

            result = yield( self )
         ensure
            previous.each do |name, value|
               instance_variable_set( "@#{name.to_s}", value )
            end
         end

         result
      end
   end


   #===========================================================================================
   if !method_defined?(:specialize_method_name) then

      #
      # Returns a specialized Symbol version of the supplied name, base on this object's class name.
      #
      # Example:
      #    <object:SomeClass>.specialize("process") => :process_some_class

      def specialize_method_name( name )
         return "#{name}#{(is_a?(Class) ? self : self.class).unqualified_name.gsub(/[A-Z]/){|s| "_#{s.downcase}"}}".intern
      end


      #
      # Sends a specialized method to this object.  Will follow the class hierarchy for the
      # determinant object, searching for a specialization this object supports.  Failing that, 
      # your fallback block will be called with the +determinant+ and +parameters+, or the 
      # routine will +fail()+.

      def send_specialized( name, determinant, *parameters, &fallback )
         determinant_class = determinant.is_a?(Class) ? determinant : determinant.class
         current_class = determinant_class
         while current_class
            specialized = current_class.specialize_method_name(name)
            return self.send( specialized, determinant, *parameters ) if self.responds_to?(specialized)
            current_class = current_class.superclass
         end
         
         if fallback then
            return fallback.call(determinant, *parameters)
         else
            fail "unable to find specialization of #{name} for #{determinant_class.name}"
         end
      end
      
   end
end
   



# =============================================================================================
#                                       Module Extensions
# =============================================================================================

class Module
   
   #===========================================================================================
   if !method_defined?(:unqualified_name) then
      
      #
      # Returns the unqualified class name.
      
      def unqualified_name()
         @unqualified_name ||= self.name.split("::").last
      end
   end
   
   
end


# =============================================================================================
#                                        Class Extensions
# =============================================================================================

class Class
   
   #===========================================================================================
   if !method_defined?(:namespace_module) then
      
      #
      # Returns the namespace in which the class is defined.
      
      def namespace_module()
         unless defined?(@namespace_module)
            if marker = self.name.rindex("::") then
               namespace_name = self.name[0..(marker-1)]
               @namespace_module = eval(namespace_name)
            else
               @namespace_module = nil
            end
         end
         
         @namespace_module
      end
   end
   
   
   #===========================================================================================
   if !method_defined?(:define_subclass) then

      #
      # Creates a subclass of this class, with the specified name and (optionally) definition. 

      def define_subclass( name, container = Object, &block )
         container.const_set( name, block ? Class.new(self, &block) : Class.new(self) )
      end
      
   end
   
   
   #===========================================================================================
   if !method_defined?(:define_instance_method) then

      #
      # Defines a new instance method, given one or more Procs.  Pass true after name if you want to
      # keep any existing method's functionality as part of the new function.
      #
      # BUG: There is probably a more efficient way to do this, and you should eventually go find it.

      def define_instance_method( name, *blocks, &block )
         blocks << block if block
         blocks.compact! if blocks.first.nil?

         #
         # Because this is a class-level function, the user's blocks don't have an object context, and 
         # we need to give them one.  In order to do this, we must convert the blocks to methods, so we 
         # can bind them to the object when called.  The same goes for any wrapper method we create.  
         # In order to avoid polluting the namespace, we just use the method name each time, replacing 
         # each existing method with the block version, and than with a wrapper method that calls them
         # both, by way of variables.  Note: because of this last bit (the use of variables to hold the
         # different versions, we can't eliminate the tail recursion, as we need a separate "copy" of
         # the variables for each wrapper.

         current_method = nil
         if blocks.first === true then
            blocks.shift
            begin; current_method = instance_method(name) ; rescue Exception ; end
         end

         send( :define_method, name, &(blocks.shift) )

         if current_method then
            block_method = instance_method( name )
            send( :define_method, name ) do |*args|
               current_method.bind(self).call(*args)
               block_method.bind(self).call(*args)
            end  
         end
      
         define_instance_method( name, true, *blocks ) unless blocks.empty?
      end
   end
   

   #===========================================================================================
   if !method_defined?(:define_class_method) then

      #
      # Defines a new Class method, given one or more Procs.

      def define_class_method( name, *blocks, &block )
         instance_class.define_instance_method( name, *blocks, &block )
      end
   end
end




# =============================================================================================
#                                       Exception Extensions
# =============================================================================================

class Exception

   #
   # Defines a simple Exception class that takes a standard parameter list and provides
   # retrievers to access them.
      
   def self.define( *parameters )
      Class.new(self) do
         @@defined_subclass_field_lists[self] = parameters
      
         define_method(:initialize) do |*values|
            super()
            @@defined_subclass_field_lists[self.class].each{|name| instance_variable_set("@#{name}".intern, values.shift)}
         end

         parameters.each do |name|
            attr_reader "#{name}".intern
         end
      end         
   end

   @@defined_subclass_field_lists = {}
   

   #===========================================================================================
   if !method_defined?(:failsafe_message) then
      
      #
      # A version of message() that kills the current thread if message() hangs (which
      # it has often done, in the past). 
      #
      # BUG: Is this an issue in current Ruby versions?

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


   #===========================================================================================
   if !method_defined?(:relative_backtrace) then
      
      #
      # Produces a backtrace with file paths relative to the specified directory.

      def relative_backtrace( relative_to, skip_qa_routines = true )
         relative_to = File.expand_path(relative_to.sub(/\/$/, "")) + "/" if relative_to

         relative_backtrace = []
         backtrace.each do |line|
            path, rest = line.split(":", 2)
            absolute_path = File.expand_path(path)
         
            relative_backtrace << (absolute_path.start_with?(relative_to) ? absolute_path[(relative_to.length)..-1] : absolute_path) + ":" + rest
         end
      
         relative_backtrace
      end
   end
   
   
   #===========================================================================================
   if !method_defined?(:generate_report) then
      
      #
      # Generates a nice-looking, informative error report for the exception.
   
      def generate_report( relative_to = nil, stream = $stderr, backtrace_levels = 15, skip_qa_routines = true )
         if ENV.member?("TM_LINE_NUMBER") then 
            print_data( stream ) if respond_to?("print_data")
            raise
         else
            heading   = "CAUGHT #{self.class.name}"
            message   = failsafe_message
            backtrace = relative_backtrace(relative_to, skip_qa_routines)
         
            stream.puts( "=" * (message.length > 60 ? message.length : 60) )
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
end





# =============================================================================================
#                                         Array Extensions
# =============================================================================================

class Array
   
   #===========================================================================================
   if !method_defined?(:exist?) then
      
      #
      # A synomym for !empty?
   
      def exist?()
         !empty?
      end
   end
   
   
   #===========================================================================================
   if !method_defined?(:push_and_pop) then
      
      #
      # Pushes an element before calling your block, then pops it again before returning.
   
      def push_and_pop( element )
         result = nil
      
         begin
            push element
            result = yield()
         ensure
            pop
         end
      
         result
      end
   end
   
   
   #===========================================================================================
   if !method_defined?(:to_hash) then
      
      #
      # Converts the elements of this array to keys in a hash and returns it.  The item itself will be used 
      # as value if the value you specify is :value_is_element.  If you supply a block, it will be used to 
      # obtain keys from the element.
   
      def to_hash( value = nil, iterator = :each )
         hash = {}
      
         send(iterator) do |*data|
            key = block_given? ? yield( *data ) : data.last
            if value == :value_is_element then
               hash[key] = data.last
            else
               hash[key] = value
            end
         end
      
         return hash
      end
   end
   
   
   #===========================================================================================
   if !method_defined?(:rest) then

      #
      # Returns all but the first element in this list.
   
      def rest( n = 1 )
         return self[n..-1]
      end
   end
   
   
   #===========================================================================================
   if !method_defined?(:last) then
      
      # 
      # Returns the last element from this list, or nil.
   
      def last()
         return self[-1]
      end
   end
   
   
   #===========================================================================================
   if !method_defined?(:top) then

      # 
      # Returns the last element from this list, or nil.
   
      def top()
         return self[-1]
      end
   end
   
end



# =============================================================================================
#                                     Enumerable Extensions
# =============================================================================================

module Enumerable

   #===========================================================================================
   if !method_defined?(:select_first) then

      # 
      # Returns the last element from this list, or nil.
   
      def select_first()
         each do |v|
            return v if yield(v)
         end
         nil
      end
   end

   #===========================================================================================
   if !method_defined?(:accumulate) then
      
      #
      # Appends your value to a list at the specified index, creating an array at that index
      # if not present.
   
      def accumulate( key, value )
         if self[key].nil? then
            self[key] = []
         elsif !self[key].is_an?(Array) then
            self[key] = [self[key]]
         end

         self[key] << value
      end
   end
   
   #===========================================================================================
   if !method_defined?(:not_empty?) then
      
      #
      # Prettier version of !enumerable.empty?
   
      def not_empty?()
         !empty?
      end
   end
   
   
end




# =============================================================================================
#                                      String Extensions
# =============================================================================================

class String
   
   if !method_defined?(:starts_with?) then
      alias :starts_with? :start_with?
   end
   
   if !method_defined?(:ends_with?) then
      alias :ends_with? :end_with?
   end
   
   if !method_defined?(:includes?) then
      alias :includes? :include?
   end
   
   if !method_defined?(:identifier_case) then
      def identifier_case()
         self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
      end
   end
   
   if !method_defined?(:camel_case) then
      def camel_case()
         identifier_case().gsub(/($|_)./,$2.upcase)
      end
   end
   
end




# =============================================================================================
#                                          Set Extensions
# =============================================================================================

#
# Note: we don't explicitly require 'set' beforehand, so this is at worst harmless.

class Set

   if !method_defined?(:subsets) then

      #
      # Returns a list of all possible subsets of the elements in this set. By way of definitions,
      # sets have no intended order and no duplicate elements

      def subsets( pretty = true )
         set     = self.dup
         subsets = [ Set.new() ]
         until set.empty?
            work_point = [set.shift]
            work_queue = subsets.dup
            until work_queue.empty?
               subsets.unshift work_queue.shift + work_point
            end
      
         end
   
         subsets.sort!{|lhs, rhs| rhs.length == lhs.length ? lhs <=> rhs : rhs.length <=> lhs.length } if pretty

         return subsets
      end
   end
   
end

def Set( *values )
   Set.new(values)
end



# =============================================================================================
#                                        Thread Extensions
# =============================================================================================

class Thread
   def self.[]( name )
      Thread.current[name]
   end
   
   def self.[]=( name, value )
      Thread.current[name] = value
   end
   
   def self.key?( name )
      Thread.current.key?(name)
   end
end



# =============================================================================================
#                                        Time Extensions
# =============================================================================================

class Time
   
   #
   # Returns a Time far in the future, or offset from now.
   
   def self.future( offsets = {} )
      if offsets.empty? then
         Time.utc(9999, 12, 31, 23, 59, 59, 999999)
      else
         days    = offsets.fetch(:days   , offsets.fetch(:day   , 0))
         hours   = offsets.fetch(:hours  , offsets.fetch(:hour  , 0))
         minutes = offsets.fetch(:minutes, offsets.fetch(:minute, 0))
         seconds = offsets.fetch(:seconds, offsets.fetch(:second, 0))
         
         Time.now() + ((((((days * 24) + hours) * 60) + minutes) * 60) + seconds)
      end
   end


   #
   # Returns a Time far in the past, or offset from now.
   
   def self.past( offsets = {} )
      if offsets.empty? then
         Time.utc(200,1,1,0,0,0)
      else
         days    = offsets.fetch(:days   , offsets.fetch(:day   , 0))
         hours   = offsets.fetch(:hours  , offsets.fetch(:hour  , 0))
         minutes = offsets.fetch(:minutes, offsets.fetch(:minute, 0))
         seconds = offsets.fetch(:seconds, offsets.fetch(:second, 0))
         
         Time.now() - ((((((days * 24) + hours) * 60) + minutes) * 60) + seconds)
      end
   end
   
   
   #
   # Measures the duration of the block you pass.
   
   def self.measure()
      start_time = Time.now()
      yield
      Time.now() - start_time
   end

end




# =============================================================================================
#                                       Quality Assurance
# =============================================================================================

module Baseline

   #
   # A mixin that provides a variety of quality-related routines.

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
      # Returns true if checks are enabled.
      
      def checks_enabled?()
         @@quality_assurance__checks_enabled
      end

   
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

      def type_check( name, object, type, allow_nil = false, data = {} )
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
            raise TypeCheckFailure.new( message, data )
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
   
      def warn_once( message, label = "WARNING", separator = ": " )
         @@quality_assurance__warnings = {} if !defined?(@@quality_assurance__warnings)
         unless @@quality_assurance__warnings.member?(message)
            warn( message, label, separator )
         end
      end

      
      #
      # Similar to warn_once(), but prepends "TODO: " when displaying the mssage.
      
      def warn_todo( message )
         warn_once(message, "TODO")
      end
   
   
      #
      # Dumps a message to $stderr.
   
      def warn( message, label = "WARNING", separator = ": " )
         label = separator = "" if label == "WARNING" && separator == ": " && message =~ /^[A-Z]+: /

         $stderr.puts "#{label}#{separator}#{message}"
         @@quality_assurance__warnings = {} if !defined?(@@quality_assurance__warnings)
         @@quality_assurance__warnings[message] = true
      end
   
   
      def self.disable_warnings()
         @@quality_assurance__warnings_enabled = false
      end
   
      def self.warnings_disabled?()
         !@@quality_assurance__warnings_enabled
      end
      
      
      #
      # Dumps a debug message to $stderr.
      
      def debug( message )
         $stderr.puts( (message =~ /^[A-Z]+: / ? "" : "DEBUG: ") + message )
      end
   
   


      # =======================================================================================
      #                                       Assertions
      # =======================================================================================

   
      #
      # Raises an AssertionFailure if the condition is false.

      def assert( condition, message = "this should not happen", data = nil, &block )
         fail( message, data, &block ) unless condition
         true
      end
   
   
      #
      # Raises an AssertionFailure outright.
   
      def fail( message = "this should not happen", data = nil, &block )
         data = block.call() if block
         raise AssertionFailure.new(message, data)
      end
   
   
      #
      # Raises an AssertionFailure indicating a method should have been overrided.

      def fail_unless_overridden( object, method )
         if object.is_a?(Class) then
            method = object.instance_class.instance_method(method) unless method.is_a?(Method)
            warn_todo("fix class name get in fail_unless_overridden()")
            fail("You must override: #{method.owner.inspect}.#{method.name} in #{object.name}")
         else
            method = object.instance_class.instance_method(method) unless method.is_a?(Method)
            fail("You must override: #{method.owner.name}.#{method.name} in #{object.class.name}")
         end
      end
      
      
      #
      # Raises an AssertionFailure indicating a method is incomplete.
      
      def fail_todo( message = nil )
         if message then
            fail("TODO: #{message}")
         else
            fail("TODO")
         end
      end
      
      
      #
      # Asserts that condition is true, but still outputs the message.
   
      def assert_and_warn_once( condition, message, data = nil, &block )
         assert( condition, message, data, &block )
         warn_once( message )
      end
   
   
      #
      # Catches any exceptions raised in your block and returns error_return instead.  Returns
      # your block's return value otherwise. You can pass a list of exceptions that should 
      # bypass the mechanism -- it's generally a good idea to let syntax and similar errors through.

      def ignore_errors( error_return = nil, unfiltered_errors = [NoMethodError] )
         begin
            return yield()
         rescue Exception => e
            unfiltered_errors.each do |clas|
               raise e if e.is_a?(clas)
            end
            
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
      
      def has?( name )
         return false if @data.nil?
         return @data.member?(name)
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

end # Baseline




# =============================================================================================
#                                        Component Locator
# =============================================================================================

module Baseline

   #
   # Given the __FILE__ path to the master file for the library, sets up a locator capable 
   # of converting file- and system-relative paths to absolute system paths.  For instance,
   # given the following structure:
   #
   # library.rb
   # library/
   #   a_file.rb
   #   subdir/
   #    b_file.rb
   #    c_file.rb
   #
   # ComponentLocator.new( "/full/path/to/library.rb" ) will be able to locate "library/a_file.rb" from
   # anywhere, and "b_file.rb" from inside "c_file.rb".
   #
   # If you wish to wrap the Locator object in your own function, add 1 to levels_back for each wrapper.

   class ComponentLocator

      def initialize( master_path, levels_back = 1 )
         @system_name = File.basename(master_path, ".rb")
         @system_base = File.expand_path(File.dirname(master_path))
         @levels_back = levels_back
      end


      #
      # Calculates the absolute path to a file within the system.  For paths beginning with the
      # library base, calculation is relative to the system home directory, unless allow_from_root is cleared.  
      # Otherwise, the path is calculated relative the caller's directory.

      def locate( path, allow_from_root = true )
         File.expand_path(path, allow_from_root && system_relative?(path) ? @system_base : find_caller_path())
      end


   private   
      def system_relative?(path)
         return false unless path[0..(@system_name.length - 1)] == @system_name
         return path[@system_name.length, File::SEPARATOR.length] == File::SEPARATOR
      end

      #
      # Figures out the file path of the script in which we were called.  We'll search the stack
      # for "locate" and step up the requisite levels from there.

      def find_caller_path()
         stack = caller(0)
         until stack.empty?
            line = stack.shift
            break if line =~ /locate.$/
         end

         (@levels_back - 1).times { stack.shift }

         abort "can't find the caller's path in the stack" if stack.empty?

         return File.dirname(File.expand_path(stack.shift.split(":")[0], Dir.pwd()))
      end
   end # ComponentLocator
   
end # Baseline




# =============================================================================================
#                                           Wildcard
# =============================================================================================

module Baseline
   
   #
   # Allows UNIX-style wildcard expressions to be compiled into regular expressions. Each wildcard 
   # character is considered a group, and the expression is required to match the whole text. The 
   # search text is expected to be a file path!
   #
   # Wildcard special characters:
   #  *   matches any character
   #  ?   matches one character
   #  .   matches only itself
   #  **/ at the beginning of the text or following a slash, matches 0 or more directories

   class Wildcard 
      include QualityAssurance
      extend  QualityAssurance

      #
      # The first clause of these two patterns matches escaped wildcards,
      # which are generally ignored.  The second clause matches unescaped
      # wildcards or other special characters.

      @@pattern    = /((?:^|[^\\])(?:\\\\)*[\\][*?])|((?:(?:^|\/)\*\*\/)|(?:[*?]))/ 
      @@compiler   = /((?:^|[^\\])(?:\\\\)*[\\][*?.])|((?:(?:^|\/)\*\*\/)|(?:[*?.]))/ 

      @@expansions = { "."    => "\\."                \
                     , "*"    => "([^/]+)"            \
                     , "?"    => "([^/])"             \
                     , "**/"  => "\\A(/?(?:[^/]+/)*)" \
                     , "/**/" => "(/(?:[^/]+/)*)"     }


      #
      # A synonym for Wildcard.new(). By default, the wildcard will match the end of the
      # string only. If you need it to match the full width, set +full_width+ to true.

      def Wildcard.compile( expression, match_end = true, match_beginning = false, case_insensitive = true )
         return Wildcard.new(expression, match_end, match_beginning, case_insensitive)
      end


      #
      # The pattern will work intuitively on path texts.  
      # Currently handles only UNIX style paths.

      def initialize( expression, match_end = true, match_beginning = false, case_insensitive = true )

         type_check( :expression, expression, String )

         @mapped           = false            # Set true once the source expression has been mapped (see map() below)
         @map              = []               # A list of the wildcard patterns in the source expression
         @compiled         = nil              # The compiled Wildcard expression
         @uncompiled       = expression       # The raw wildcard text from which this Wildcard is compiled
         
         @match_end        = match_end
         @match_beginning  = match_beginning
         @case_insensitive = case_insensitive

         regex = @uncompiled.gsub(@@compiler) do |match|
            if $1.nil? then  
               @@expansions[match]
            else
               match
            end
         end
         
         regex = regex + "\\Z" if @match_end
         regex = "\\A" + regex if @match_beginning

         @compiled = Regexp.compile(regex, @case_insensitive ? "i" : nil)

      end



    #-----------------------------------------------------------------------------
    # REGEXP OPERATIONS

      def ===( string )
         @compiled === string
      end

      def =~( string )
         @compiled =~ string
      end

      def casefold?()
         @case_insensitive
      end

      def match( string, store = false )
         m = @compiled.match(string)
         Thread.current[:baseline_wildcard_last_match] = m if store
         m
      end
      
      def last_match()
         Thread.current[:baseline_wildcard_last_match]
      end

      def source()
         @uncompiled
      end

      def intermediate()
         @compiled.source
      end



    #-----------------------------------------------------------------------------
    # ADDITIONAL OPERATIONS

      #
      # Splices the matching text from one wildcard search into another wildcard
      # expression.  +into+ and +text+ must be Strings.  Returns nil if the text
      # doesn't match this Wildcard.

      def splice( into, text )

         type_check( :into, into, String )
         type_check( :text, text, String )

         result = nil
         m = @compiled.match( text )

         unless m.nil?

            #
            # Construct lists of result for each wildcard type

            common = []
            matches = { "*" => [], "?" => [], "**/" => common, "/**/" => common }

            map()
            @map.each_index do |index|
               type = @map[index]
               matches[type].push( m[index+1] )
            end
         

            #
            # And construct the result string

            result = m.pre_match + into + m.post_match 

            result.gsub!( @@pattern ) do |match|
               if $1.nil? then
                  if match.begins("/") and not matches[match].empty? and not matches[match][0].begins("/") then
                     "/" + matches[match].shift()
                  else
                     matches[match].shift()
                  end
               else
                  match
               end
            end

         end

         return result

      end



      #
      # Returns the number of wildcard characters found in the string.

      def Wildcard.count( string )

         count = 0

         if string.is_a?(String) then
            matches = string.scan(@@pattern)
            matches.each do |pair|
               if pair[0].nil? then
                  count += 1
               end
            end
         end

         return count
      end


      #
      # Returns true if the string holds directory delimiters.

      def Wildcard.directory?( string )
         return true if string =~ /\//
      end


    #-----------------------------------------------------------------------------
    # PRIVATE METHODS

    private

      #
      # Makes a list of the wildcard characters in the source expression.

      def map()
         unless @mapped
            @mapped = true
            @map    = []

            matches = @uncompiled.scan(@@pattern)
            matches.each do |pair|
               if pair[0].nil? then
                  @map.push( pair[1] )
               end
            end
         end
      end


   end  # Wildcard

end # Baseline

