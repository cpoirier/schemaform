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
# Base class for values and variables and results within an expression.

module Schemaform
module Language
class Placeholder
   include QualityAssurance
   extend  QualityAssurance

   def initialize( type, production = nil )
      @type       = type
      @production = production
   end
      
   warn_once("remove type(), production(), and description() placeholders once testing is complete")
   
   def type()
      fail "rename to get_type()"
   end
   
   def production()
      fail "rename to get_production()"
   end
   
   def description()
      fail "rename to get_description()"
   end
   
   def get_type()
      @type
   end
   
   def get_production()
      @production
   end
   
   def ==( rhs )
      @type.capture_method(self, :==, [rhs])
   end
   
   def method_missing( symbol, *args, &block )
      @type.capture_method(self, symbol, args, block) or fail "cannot dispatch [#{symbol}] on type #{@type.description} (#{@type.class.name})"
   end
   
   def print_to( printer )
      if @production then
         printer.label( "#{get_description} resulting from #{@production.description}" ) do
            @production.print_to(printer, false)
         end
      else
         printer.print("#{get_description}")
      end
   end
   
   def get_description()
      "#{get_type.description}"
   end
   
end # Placeholder
end # Language
end # Schemaform


Dir[Schemaform.locate("placeholders/*.rb")].each{|path| require path}
