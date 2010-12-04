#!/usr/bin/env ruby -KU
#================================================================================================================================
# Copyright 2002 Chris Poirier (cpoirier@gmail.com)
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
# A reference object

class Reference
   def initialize( value = nil )
      @value = value
   end

   def nil?()
      return @value.nil?
   end

   def each()
      yield( @value ) unless @value.nil?
   end

   def <<( value )
      @value = value
   end

   def to_s()
      return @value.to_s
   end

   def length()
      return @value.nil? ? 0 : 1
   end

   attr_accessor :value

   def method_missing( symbol, *args )
      if block_given? then
         @value.send( symbol, *args ) do |*data|
            yield( *data )
         end
      else
         @value.send( symbol, *args )
      end
   end 
end

def reference( value = nil )
   return Reference.new( value )
end

def Reference( value = nil )
   return Reference.new( value )
end
