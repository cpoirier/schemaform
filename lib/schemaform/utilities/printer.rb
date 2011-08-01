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
   
   def self.dump( object )
      Printer.run do |printer|
         printer.puts(object)
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
      when nil, :square
         header = "#{label}#{separator}"

         print header
         indent(header.length) do
            yield
         end
      when :simple
         body = buffer(false){ yield }
         body.chomp!
         
         if body.includes?("\n") then
            puts "#{label}#{separator}"
            indent(){ puts(body) }
         else
            puts "#{label}#{separator}#{body}"
         end
      end
   end

   
   #
   # Writes some text to the stream.
   
   def <<( text )
      print(text)
      self
   end


   #
   # Writes a full line of text, with end of line marker, to the stream.
   
   def puts( text = "" )
      print( text )
      end_line()
   end


   #
   # Writes data to the stream.
   
   def print( data )
      return if data.nil?

      case data
      when NilClass
         # no op
      when String
         if @at_bol then
            @stream << @indent
            @at_bol = false
         end

         if data[-1..-1] == "\n" then
            @at_bol = true
            @stream << data.slice(0..-2).gsub("\n", "\n#{@indent}")
            @stream << "\n"
         else
            @stream << data.gsub("\n", "\n#{@indent}")
         end
      when Array
         data.each_with_index do |value, i|
            label("[#{i}]", ""){puts(value)}
         end
      when Hash
         data.each do |name, value|
            label("[#{name}]", ""){puts(value)}
         end
      else
         if data.responds_to?(:print) then
            data.print(self)
         elsif data.responds_to?(:to_s) then
            print(data.to_s)
         else
            print(data.inspect)
         end
      end
   end

   
   #
   # Ends the current line.
   
   def end_line()
      print("\n") unless @at_bol
   end

   
   #
   # Displays some number of blank lines. Ends the current line if pending.
   
   def blank_lines( count = 2 )
      end_line()
      count.times { puts }
   end

   
   #
   # Initiates a temporary buffer within the indenter. If the block exits normally, any text written
   # during your block will be written to the real stream or returned.
      
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

      commit ? print(buffer) : buffer
   end


end # Printer


