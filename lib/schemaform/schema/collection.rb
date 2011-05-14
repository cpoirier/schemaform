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

require Schemaform.locate("element.rb")
require Schemaform.locate("type.rb")


#
# Base class for things that contain other things.

module Schemaform
class Schema
class Collection < Element

   def initialize( member, context, name = nil, type_class = Schema::CollectionType )
      super(context, name)
      @member     = member
      @type_class = type_class
   end

   attr_reader :member
   
   def type()      
      @type = @type_class.new(@member.type) if @type_class.nil?
      @type
   end
   
   def recreate_in( new_context, changes = nil )
      self.class.new(@member.recreate_in(new_context), new_context, @name, @type_class)
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
   #       handler = @definition.definition.marker(ImpliedContext.new(self))
   #       handler.send(symbol, *args, &block)
   #    end
   # end # AttributeVariable
   # 
   # 
   # def marker( production )
   #    AttributeVariable.new(self, production)
   # end
   # 
   
   
end # Collection
end # Schema
end # Schemaform
