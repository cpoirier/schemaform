#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2004-2009 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================


require( File.dirname(File.expand_path(__FILE__)) + "/object.rb" )



#
# CommandProcessor
#  - a harness for command line utilities
#  - initialize it with your command line parameters, and then pass process() a block to execute
#  - process() never raises an exception, and generates a report to $stderr for anything it catches
#  - process() returns an rc for use with exit()
#  - subclass and implement report_*() to generate custom error reports for specific exception classes
#

class CommandProcessor

   attr_accessor :product
   
   
   #
   # initialize()
   #  - parses the parameters into flags and files and preps the CommandProcessor for use
   
   def initialize( parameters, flag_default = nil, product = nil )

      @product = product
      
      #
      # Parse the parameters into files and flags.
      
      @files = Array.new()
      @flags = Hash.new( flag_default )

      done_flags = false 
      parameters.each do |parameter|
         if !done_flags then
            if parameter == "--" then
               done_flags = true
            elsif parameter.slice(0,2) == "--" then
               parse_flag( parameter.slice(2, parameter.length-2), @flags )
            elsif parameter.slice(0,1) == "-" then
               parse_flag( parameter.slice(1, parameter.length-1), @flags )
            else
               done_flags = true
               @files << parameter
            end
         else
            @files << parameter
         end 
      end
      
   end
   
   #
   # Constructs the command process, calls your block, and returns or exits appropriately.
   # Any parameters from initialize() or process() can be passed via the control hash.  
   # Set :exit if you want to exit on completion.
   
   def self.process( parameters, control = {} )
      cp = self.new( parameters, control.fetch(:flag_default, nil), control.fetch(:product, nil) )
      rc = cp.process( control.fetch(:load_tools, true), control.fetch(:hijack_std, true) ) do |flags, files|
         yield( flags, files )
      end
      
      if control.fetch(:exit, false) then
         exit(rc)
      else
         return rc
      end
   end


   #
   # process()
   #  - calls your block, capturing all errors and referring them to report_* for reporting
   #  - returns 0 on success, some higher integer on failure (for use with exit)

   def process( load_tools = true, hijack_std = true )
      rc = 1
      
      begin
         
         #
         # Load all tools.
         
         if load_tools then
            Dir["#{File.dirname(File.expand_path(__FILE__))}/*.rb"].each {|path| require path }
            if hijack_std then
               ContextStream.hijack_std() 
            end
         end         
         
         # 
         # Yield to the user's block to process.
         
         yield( @flags, @files )
         rc = 0
         
      rescue SystemExit 
         raise
      rescue Interrupt
         rc = report_terminated()
      rescue Errno::EPIPE
         rc = report_terminated()
      rescue Exception => e
         rc = send_specialized( "report", "exception", e )
      ensure

         #
         # Clean up any worker threads.
         
         main_thread = Thread.current
         Thread.list.each do |thread|
            thread.kill unless thread.object_id == main_thread.object_id
         end
      end

      return rc
   end


   #
   # report_exception()
   #  - generates a default report for an otherwise unhandled exception
   
   def report_exception( e, stream = $stderr, message = nil, display_exception_class = true )
      message = e.class.method_defined?("failsafe_message") ? e.failsafe_message : e.message if message.nil?

      stream.puts
      stream.puts( "CAUGHT A BUG!" )
      stream.indent do
         stream.puts
         stream.puts( (display_exception_class ? e.class.name + ": " : "") + message )
         stream.indent do
            if @flags.member?("enable-backtraces") then
               print_backtrace( e.backtrace, stream )
            else
               print_backtrace( e.backtrace[0..14], stream )
               if e.backtrace.length > 15 then
                  stream.puts( " . . . #{e.backtrace.length-15} more entries" ) 
               end
            end
         end
         stream.puts
      end
      
      return 2
   end
   
   
   def report_load_error( e, stream = $stderr ) 
      message = e.class.method_defined?("failsafe_message") ? e.failsafe_message : e.message
      message = "no such file to load -- " + (@product ? @product.relative_install_directory($1) : $1) if message =~ /no such file to load -- (.*)$/
      return report_exception( e, stream, message )
   end

   
   def report_n_y_i( e, stream = $stderr )
      message = "NOT YET IMPLEMENTED: " + (e.class.method_defined?("failsafe_message") ? e.failsafe_message : e.message)
      return report_exception( e, stream, message, false )
   end
   
   
   def report_bug( e, stream = $stderr )
      message = "BUG: " + (e.class.method_defined?("failsafe_message") ? e.failsafe_message : e.message)
      return report_exception( e, stream, message, false )
   end
   
   
   def report_terminated( stream = $stdout )
      stream.puts( " . . . terminated." )      
      return 1
   end
   
   
   #
   # print_backtrace()
   #  - prints the backtrace to the specified stream
   
   def print_backtrace( elements, stream = $stderr )
      elements.each do |line| 
         stream.puts( "• " + (@product ? @product.relative_install_directory(line) : line) )
      end
   end
   
   
   
private


   #
   # parse_flag()
   #  - parses a single command line flag
   
   def parse_flag( text, into )
      pieces = text.split( "=", 2 )
      
      if pieces.length == 1 then
         into[pieces[0]] = true
      else
         into[pieces[0]] = pieces[1]
      end 
   end
      
end




#
# Test the class.

if $0 == __FILE__
   parsed = Tapestry::CommandLineParser.new( )

   if parsed.flags.empty? then
      puts( "No flags." )
   else
      puts( "Flags:" )
      parsed.flags.keys.each do |key|
         puts( "   " + key + " = " + parsed.flags[key] )
      end
   end

   puts( "" )
   if parsed.files.empty? then
      puts( "No files." )
   else
      puts( "Files:" )
      parsed.files.each do |file|
         puts( "   " + file )
      end
   end

end
