#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2004-2008 Chris Poirier (cpoirier@gmail.com)
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the 
# License.  You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language 
# governing permissions and limitations under the License.
#================================================================================================================================


class String
   
   attr_accessor :source
   alias contains? include?
   
   
   #
   # Converts the string to a plural form.  It's simple
   # stupid concatenation...

   def pluralize( count = 2, plural_form = nil )
      if count == 1 then
         return self
      else
         if plural_form.nil? then
            if self[-1..-1] == "y" then
               return self[0..-2] + "ies"
            elsif self[-1..-1] == "s" then
               return self + "es"
            else
               return self + "s"
            end
         else
            return plural_form
         end
      end
   end


   #
   # each_index_of()
   #  - calls your block with each position of the search string
   
   def each_index_of( search, pos = 0 )
      while next_pos = ruby_index( search, pos )
         yield( next_pos )
         pos = next_index + 1
      end
   end


   #
   # escape()
   #  - returns a string with newline etc. escaped
   
   def escape()
      self.inspect.slice(1..-2).gsub("\\\"", "\"").gsub("\\'", "'")
   end
   
   
   #
   # <<
   #  - adds unicode character code support to the standard << 

   alias ruby_append <<
   
   def <<( data )
      if data.is_a?(Numeric) then
         self << [data].pack("U*")
      else
         ruby_append( data )
      end
   end
   
   
   def write( data )
      ruby_append( data )
   end
   
   
   
   #
   # Returns true if the string begins with the specified substring.

   def begins?( with )
      return (slice(0, with.length) == with)
   end

   alias begins begins?

  
   #
   # Returns true if the string ends with the specified substring. 

   def ends?( with )
      length = with.length
      return (length > 0 ? (slice(-length..-1) == with) : true )
   end

   alias ends ends?


   #
   # If self starts with string, returns the rest of self.  Otherwise
   # returns nil.

   def after( string )
      after = nil
      if begins(string) then
         after = slice(string.length..-1)
      end
      return after
   end

   #
   # Gets substring from the start of the string

   def first( length = 1 )
      return self[0..length-1]
   end

   #
   # Gets substring from the end of the string

   def last( length = 1 )
      return self[(-length)..-1]
   end

   #
   # Gets substring from after the start of the string

   def rest( from = 1 )
      return self[from..-1]
   end
   
   
   #
   # Creates a copy of this Token with the specified text prefixed to our text.

   def prefix( prefix, glue = nil )
      return (prefix.nil? ? "" : prefix + glue.to_s) + self
   end
   
   
   #
   # Creates a copy of this Token with the specified text suffixed to our text.
   
   def suffix( suffix, glue = nil )
      return self + (suffix.nil? ? "" : glue.to_s + suffix)
   end

   
   
   #
   # Capitalizes each word in the string.

   WORD_PATTERN = /(\w+)/

   def capitalize_words()
      return self.gsub( WORD_PATTERN ) do |match|
         match.capitalize
      end
   end


   #
   # Splits the string on whitespace strings.

   WHITESPACE_PATTERN = /\s+/
   
   def split_on_whitespace( limit = nil )
      if limit then
         return self.split(WHITESPACE_PATTERN, limit)
      else
         return self.split(WHITESPACE_PATTERN)
      end
   end


   #
   # Returns true iff the string is all whitespace.

   def whitespace?( or_empty = true )
      if or_empty and self.empty? then
         return true
      elsif m = WHITESPACE_PATTERN.match(self) then
         return m[0].length == self.length
      end
      return false
   end

 
   #
   # Strips only trailing whitespace from each line.

   TRAILING_WHITESPACE_PATTERN = /\s+$/

   def strip_trailing()
      return self.gsub(TRAILING_WHITESPACE_PATTERN, "")
   end

   
   #
   # Strips the trailing newline from a string

   END_OF_LINE_PATTERN = /\r?\n$/

   def strip_end_of_line()
      return self.sub(END_OF_LINE_PATTERN, "")
   end

   
   #
   # Returns a string in which each line begins and ends
   # with no whitespace (other than the newline) and runs
   # of space within each line are reduced to a single
   # space.

   SPACE_PATTERN          = / +/
   LEADING_SPACE_PATTERN  = /^ /
   TRAILING_SPACE_PATTERN = / $/

   def compress_space()
      return self.dup.compress_space!
   end

   def compress_space!()
      self.gsub!( SPACE_PATTERN, " " )
      self.gsub!( LEADING_SPACE_PATTERN, "" )
      self.gsub!( TRAILING_SPACE_PATTERN, "" )

      return self
   end


   #
   # Returns the number of lines in the string, as
   # would be output by puts(), which appends a trailing
   # newline only if necessary.

   def lines()
      return self.count("\n") + (self.ends("\n") ? 0 : 1)
   end


   #
   # Returns true if the string is a number (only).

   NUMERIC_PATTERN = /\A(\+|\-)?((\d+(\.\d*)?)|(\.\d+))\Z/

   def numeric?()
      return (self =~ NUMERIC_PATTERN)
   end

   INTEGER_PATTERN = /\A(\+|\-)?\d+\Z/

   def integer?()
      return (self =~ INTEGER_PATTERN)
   end


   #
   # For better interface compatibility with IO.

   def puts( data )
      self << data << "\n"
   end
   



end


