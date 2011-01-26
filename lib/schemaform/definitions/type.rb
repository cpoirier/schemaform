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


#
# Base class for all Schemaform types.  Unlike Ruby, databases are (necessarily) rather strongly 
# typed, and the typing system provides a way to manage assignment and join compatibility,
# among other things.

module Schemaform
module Definitions
class Type < Base

   def initialize( schema )
      super( schema )
   end
      

   #
   # Returns a human-readable summary of the type, for inclusion in diagnostic output.
   
   def description()
      return name.to_s if named?
      return "<unnamed type of dimensionality #{dimensionality}>"
   end

   
   #
   # Returns the "dimensionality" or order of this type: 0 for scalar, 1 for tuple, 2 for relation.
   
   def dimensionality()
      fail_unless_overridden( self, :dimensionality )
   end

   
   #
   # Resolves any deferred typing information within the Type.
   
   def resolve( supervisor )
      fail_unless_overridden( self, :resolve )
   end

   
   #
   # Iterates over this and any Type this one is built with.
   
   def each_effective_type()
      yield( self )
   end

   
end # Type
end # Definitions
end # Schemaform

Dir[Schemaform.locate("types/*.rb")].each { |path| require path }


