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
# A wrapper on a Schema-defined Tuple that provides services to a runtime Tuple class. 

module Schemaform
module Plan
class Tuple
   
   UndefinedAttributeException = Exception.define(:name)
   
   
   def initialize( definition )
      type_check(:definition, definition, Model::Tuple)
      @definition = definition
   end
   
   #
   # Returns the Plan for the named Attribute.
   
   def []( name )
      raise UndefinedAttributeException.new(name) unless member?(name)
      @definition[name].plan
   end

   
   #
   # Returns true IFF the symbol names a gettable attribute of the Tuple.
   
   def member?( symbol )
      @definition.member?(symbol)
   end


   #
   # Returns true IFF the symbol names a settable attribute of the Tuple.
   
   def settable?( symbol )
      @definition.member?(symbol) && @definition[symbol].settable?
   end
   
   
   #
   # Returns true IFF the symbol names a Tuple-valued attribute.
   
   def tuple_valued?( symbol )
      @definition.member?(symbol) && @definition[symbol].tuple_valued?
   end
   
   
   #
   # Validates a Hash or Registry of attributes against the template. Any missing
   # optional attributes
   
   def validate( pairs )
      check do
         pairs.each do |name, value|
            assert(@definition.attribute?(name))
         end
      end
      
      fail_todo
      
      @definition.each do |attribute|
         warn_todo("type checking of attributes during tuple validation")
         if pairs.member?(attribute.name) then
         end         
      end      
   end


end # Tuple
end # Plan
end # Schemaform