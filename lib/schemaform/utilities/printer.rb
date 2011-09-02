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


#
# Wraps a Ruby Stream to simplify printing indented data to a terminal.

class Printer
   attr_reader :stream
   attr_reader :indent
   
   def self.run( stream = $stdout, indent = "" )
      yield(new(stream, indent))
   end
   
   def self.print( object, indent = "DUMP: ", stream = $stdout )
      Printer.run(stream, indent) do |printer|
         printer.print(object)
      end
   end
   
   def initialize( stream = $stdout, indent = "" )
      @stream     = stream
      @indent     = indent
      @at_bol     = true
      @properties = {}
   end
   
   
   
   #
   # Returns the named property's current value, or nil
   
   def []( name )
      return @properties[name]
   end
   
   
   #
   # Sets a named property (without any scope management).
   
   def []=( name, value )
      @properties[name] = value
   end
   

   #
   # Adds information to the indenter properties, returning to the old state on return.
   
   def with( pairs )
      old = pairs.keys.each{|name| @properties[name]}
      begin
         pairs.each{|name, value| @properties[name] = value}
         yield
      ensure
         old.each{|name, value| @properties[name] = value}
      end      
   end
   


   #
   # Adds indent to any output during your block.
   
   def indent( additional = "   " )
      old_indent = @indent
      begin
         additional = " " * additional if additional.is_a?(Numeric)
         @indent += additional
         return yield(self)
      ensure
         @indent = old_indent
      end
   end
   
   
   #
   # Prints out the label and the contents of your block, on one line if possible, or indented
   # under the label if not.

   def label( label, terminator = ":", separator = "#{terminator} " )
      case self[:label_style]
      when :square
         header = "#{label}#{separator}"

         print header
         indent(header.length) do
            yield
         end
      when nil, :simple
         body = buffer(false){ yield }
         body.chomp!
         
         if body.includes?("\n") || @newlines_suppressed then
            print "#{label}#{separator}"
            indent(){ print(body) }
         else
            print "#{label}#{separator}#{body}"
         end
      end
   end

   
   #
   # Prints an object to the stream. Note that print() does not follow the Ruby convention
   # about ending the line: print always acts in block mode, unless you set inline to true,
   # in order to give intuitive results when printing complex objects. It is probably better 
   # to do your own string converstion and use << if you want direct control over line endings.
   
   def print( data, inline = false )
      return if data.nil?

      case data
      when NilClass
         # no op
      when String
         self << data
      when Array
         data.each_with_index do |value, i|
            label("[#{i}]", ""){print(value)}
         end
      when Hash
         data.each do |name, value|
            label("[#{name}]", ""){print(value)}
         end
      else
         if data.responds_to?(:print_to) then
            data.print_to(self)
         elsif data.responds_to?(:to_s) then
            print(data.to_s)
         else
            print(data.inspect)
         end
      end
      
      end_line() unless inline
   end


   #
   # Writes some text to the stream.
   
   def <<( text )
      if @at_bol then
         @stream << @indent
         @at_bol = false
      end
      
      if text[-1..-1] == "\n" then
         @at_bol = true
         @stream << text.slice(0..-2).gsub("\n", "\n#{@indent}")
         @stream << "\n"
      else
         @stream << text.gsub("\n", "\n#{@indent}")
      end
      
      self
   end



   
   #
   # Ends the current line.
   
   def end_line()
      self << "\n" unless @at_bol
   end

   
   #
   # Displays some number of blank lines. Ends the current line if pending.
   
   def blank_lines( count = 2 )
      end_line()
      count.times { self << "\n" }
   end

   
   #
   # Initiates a temporary buffer within the indenter. If the block exits normally, any text written
   # during your block will be written to the real stream. Returns the buffered text.
      
   def buffer( commit = true )
      state   = [@stream, @at_bol, @indent]
      @stream = buffer = ""
      @at_bol = false
      @indent = ""
      
      begin
         yield
      ensure
         @stream, @at_bol, @indent = *state
      end

      self << buffer if commit
      buffer
   end


end # Printer


