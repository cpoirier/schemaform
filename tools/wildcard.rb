#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2004-2005 Chris Poirier (cpoirier@gmail.com)
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
# Extends Regexp to allow wildcard expressions to be compiled into regular expressions.  Each wildcard character is considered a 
# group, and the expression is required to match the whole text.  The search text is expected to be a file path!
#
# Wildcard special characters:
#  *   matches any character
#  ?   matches one character
#  .   matches only itself
#  **/ at the beginning of the text or following a slash, matches 0 or more directories

class Wildcard 

   @compiled   = nil     # The compiled Wildcard expression
   @uncompiled = nil     # The raw wildcard text from which this Wildcard is compiled

   @mapped     = false   # Set true once the source expression has been mapped (see map() below)
   @map        = []      # A list of the wildcard patterns in the source expression


   #
   # The first clause of these two patterns matches escaped wildcards,
   # which are generally ignored.  The second clause matches unescaped
   # wildcards or other special characters.

   @@pattern    = /((?:^|[^\\])(?:\\\\)*[\\][*?])|((?:(?:^|\/)\*\*\/)|(?:[*?]))/ 
   @@compiler   = /((?:^|[^\\])(?:\\\\)*[\\][*?.])|((?:(?:^|\/)\*\*\/)|(?:[*?.]))/ 

   @@expansions = { "."    => "\\."                \
                  , "*"    => "([^/]*)"            \
                  , "?"    => "([^/])"             \
                  , "**/"  => "\\A(/?(?:[^/]*/)*)" \
                  , "/**/" => "(/(?:[^/]*/)*)"     }


   #
   # A synonym for Wildcard.new()

   def Wildcard.compile( expression )
      return Wildcard.new(expression)
   end


   #
   # The pattern will work intuitively on path texts.  
   # Currently handles only UNIX style paths.

   def initialize( expression )

      type_check( expression, String )

      @uncompiled = expression
      @mapped     = false
      @map        = []

      if @uncompiled.nil? then
         @uncompiled = expression 
         raise TypeError.new("@uncompiled refused to accept assignment again") if @uncompiled.nil?
      end

      compiled = @uncompiled.gsub(@@compiler) do |match|
         if $1.nil? then  
            @@expansions[match]
         else
            match
         end
      end

      @compiled = Regexp.compile(compiled + "\\Z")

   end



 #-----------------------------------------------------------------------------
 # REGEXP OPERATIONS

   def ===( string )
      return @compiled === string
   end

   def =~( string )
      return @compiled =~ string
   end

   def casefold?()
      return false
   end

   def match( string )
      return @compiled.match(string)
   end

   def source()
      return @uncompiled
   end

   def intermediate()
      return @compiled.source
   end



 #-----------------------------------------------------------------------------
 # ADDITIONAL OPERATIONS

   #
   # Splices the matching text from one wildcard search into another wildcard
   # expression.  Into and text must be Strings.  Returns nil if the text
   # doesn't match this Wildcard.

   def splice( into, text )

      type_check( into, String )
      type_check( text, String )

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
