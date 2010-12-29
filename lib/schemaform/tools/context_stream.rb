#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2007-2008 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================


#
# class ContextStream
#  - a wrapper for STDOUT/STDERR that provides a bit of context-sensitivity for output processing.

class ContextStream
   attr_reader :stream
   attr_reader :indent
   
   def initialize( stream, indent = "" )
      @real_stream = stream
      @stream      = stream
      @indent      = indent
      @pending     = true
      @properties  = {}
   end
   
   
   #
   # ::indent_with()
   
   def self.indent_with( stream, additional = "   " )
      if stream then
         stream.indent(additional) { yield(stream) }
      else
         yield(stream)
      end
   end

   
   #
   # ::buffer_with()
   
   def self.buffer_with( stream, commit_if_not_discarded = true )
      if stream then
         stream.buffer(commit_if_not_discarded) { yield() }
      else
         yield()
      end
   end
   
   
   #
   # indent()
   #  - any output during your block will be indented from the context
   
   def indent( additional = "   " )
      if block_given? then
         old_indent = @indent
         begin
            additional = "   " * additional if additional.is_a?(Numeric)
            @indent += additional
            return yield( self )
         ensure
            @indent = old_indent
         end
      else
         @indent = additional
      end
   end
   

   #
   # with()
   #  - applies a set of name => value properties for the length of your block
   #  - properties can be retrieved with property()
   
   def with( pairs )
      old = pairs.keys.each{ |name| @properties[name] }
      begin
         pairs.each{ |name, value| @properties[name] = value }
         yield( )
      ensure
         old.each{ |name, value| @properties[name] = value }
      end      
   end
   
   
   #
   # []
   #  - returns the named property's current value, or nil
   
   def []( name )
      return @properties[name]
   end
   
   
   #
   # []=
   #  - sets a named property (without any scope management)
   
   def []=( name, value )
      @properties[name] = value
   end
   
   
   def dump( object )
      if object.responds_to?(:dump) then
         object.send( :dump, self )
      elsif object.responds_to?(@dump_inspector) then
         object.send( @dump_inspector, self )
      else
         self.puts object.inspect
      end
   end
   
   
   
   
   def <<( text )
      if text.is_a?(String) then
         write( text )
      else
         text.display( self )
      end
      self
   end


   def puts( text = "" )
      write( text )
      write( "\n" )
   end

   
   def write( data )
      string = data.to_s
      string = data.inspect if string.nil?
      
      if @pending then
         @stream.write( @indent )
         @pending = false
      end
      
      if string[-1..-1] == "\n" then
         @pending = true
         @stream.write( string.slice(0..-2).gsub("\n", "\n#{@indent}") )
         @stream.write( "\n" )
      else
         @stream.write( string.gsub("\n", "\n#{@indent}") )
      end
   end

   
   def end_line()
      write( "\n" ) unless @pending
   end

   
   def blank_lines( count = 2 )
      end_line()
      count.times { puts }
   end

   
   #
   # buffer()
   
   def buffer( commit_if_not_discarded = true )
      @stream = ""
      
      if block_given? then
         begin
            yield()
         ensure
            if commit_if_not_discarded then
               commit()
            else
               discard()
            end
         end
      end
   end

   
   #
   # commit()
   
   def commit()
      if @stream.object_id != @real_stream.object_id then
         @real_stream.write( @stream )
         @stream = @real_stream
      end
   end

   
   #
   # discard()
    
   def discard()
      @stream = @real_stream
   end
   

   def method_missing( name, *args )
      @stream.send( name, *args )
   end


   #
   # self.hijack_std()
   
   def ContextStream.hijack_std()
      $stdout = ContextStream.new( $stdout ) unless $stdout.is_a?(ContextStream)
      $stderr = ContextStream.new( $stderr ) unless $stderr.is_a?(ContextStream)
   end
   
end # ContextStream


