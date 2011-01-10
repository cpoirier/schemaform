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

require Schemaform.locate("base.rb")


module Schemaform
module Definitions
class Field < Base
   def initialize( context, name, type )
      super( context.schema )
      type_check( :context, context, Tuple )
      
      @context    = context
      @name       = name
      @path       = context.path + [name]
      @type       = type
      @expression = nil
   end
   
   attr_reader :name, :type, :path, :context, :expression

   def close()
      @expression = Expressions::Field.new(self) if @expression.nil?
   end
   
   def resolve( supervisor, tuple_expression = nil )
      fail_unless_overridden( self, :resolve )
   end
   
   
end # Field
end # Definitions
end # Schemaform


Dir[Schemaform.locate("fields/*.rb")].each {|path| require path}
