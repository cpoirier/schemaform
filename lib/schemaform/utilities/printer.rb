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


#
# Wraps a Ruby Stream to simplify printing indented data to a terminal.

class Printer
   attr_reader :stream
   attr_reader :indent
   
   def self.run( stream = $stdout, indent = "" )      
      yield(new(stream, indent))
   end
   
   def initialize( stream = [], indent = "" )
      @stream     = stream
      @indent     = indent
      @at_bol     = true
      @properties = {}
   end
   
   attr_reader :stream
   
   def to_s()
      @stream.join("")
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
      return if @stream.nil?
      return yield if label.nil? || label.empty?
      header = "#{label}#{separator}"

      case self[:label_style]
      when :square
         print header
         indent(header.length) do
            yield
         end
      when nil, :simple
         body = buffer(false){ yield }
         body.chomp!
         
         if body.includes?("\n") || @indent.length + header.length + body.length > 80 then
            print header
            indent(){ print(body) }
         else
            print "#{header}#{body}"
         end
      end
   end

   
   #
   # Prints an object to the stream. Note that print() does not follow the Ruby convention
   # about ending the line: print always acts in block mode, unless you set inline to true,
   # in order to give intuitive results when printing complex objects. It is probably better 
   # to do your own string converstion and use << if you want direct control over line endings.
   
   def print( data, end_line = true )
      return if data.nil? || @stream.nil?

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
         elsif data.responds_to?(:to_str) then
            print(data.to_str)
         else
            print(data.inspect)
         end
      end
      
      end_line() if end_line
   end
   
   
   #
   # Dumps an object to the stream with a custom indent.
   
   def dump( object, indent = "DUMP: " )
      indent(indent) do
         print(object)
      end
   end


   #
   # Writes some text to the stream.
   
   def <<( text )
      unless @stream.nil?
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
      return self if @stream.nil?
      
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


