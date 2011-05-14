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

require Schemaform.locate("collection.rb")
require Schemaform.locate("types/list_type.rb")


#
# An ordered list of scalar or tuple values.

module Schemaform
class Schema
class List < Collection

   def initialize( material, attribute, name = nil, type_class = ListType )
      super(material, attribute, name, type_class)
   end
   


   # ==========================================================================================
   #                                     Expression Interface
   # ==========================================================================================
   
   # class ListVariable < Collection::CollectionVariable 
   # 
   #    def initialize( definition, production = nil )
   #       super(definition, production)
   #    end
   #    
   #    def first!()
   #       ListMemberVariable.new(self, Expressions::FirstInListExpression(self))
   #    end
   #    
   #    def last!()
   #       ListMemberVariable.new(self, Expressions::LastInListExpression(self))
   #    end
   # 
   #    def method_missing( symbol, *args, &block )
   #       handler = @definition.definition.marker(ImpliedContext.new(self))
   #       handler.send(symbol, *args, &block)
   #    end
   # end # AttributeVariable
   # 
   # class ListMemberVariable < ExpressionResult
   #    def initialize( list_variable, production = nil )
   #       super(list_variable.definition, production)
   #       @list_variable = list_variable
   #    end
   #    
   #    def next!()
   #       fail
   #    end
   #    
   #    def previous!()
   #       fail
   #    end      
   # end
   # 
   # def marker( production )
   #    ListVariable.new(self, production)
   # end


end # List
end # Schema
end # Schemaform