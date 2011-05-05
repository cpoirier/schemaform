#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2010 Chris Poirier
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

require Schemaform.locate("thing.rb")


#
# Base class for things that contain other things.

module Schemaform
module Definitions
class Collection < Thing

   def initialize( member_definition, context, name, collection_type )
      super(context, name)
      @member_definition = member_definition
      @collection_type   = collection_type
   end
   
   attr_reader :member_definition
   
   def type()
      if @type.nil? then
         @type = @collection_type.new(@member_definition.is_a?(Type) ? @member_definition : @member_definition.type)
      end
      
      @type
   end
   
   
   
   # # ==========================================================================================
   # #                                     Expression Interface
   # # ==========================================================================================
   # 
   # class CollectonVariable < Variable
   # 
   #    def initialize( definition, production = nil )
   #       super(definition, production)
   #    end
   # 
   #    def method_missing( symbol, *args, &block )
   #       handler = @definition.definition.variable(ImpliedContext.new(self))
   #       handler.send(symbol, *args, &block)
   #    end
   # end # AttributeVariable
   # 
   # 
   # def variable( production )
   #    AttributeVariable.new(self, production)
   # end
   # 
   
   
end # Collection
end # Definitions
end # Schemaform