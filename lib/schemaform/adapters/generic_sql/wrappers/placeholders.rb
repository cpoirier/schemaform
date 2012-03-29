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

require Schemaform.locate("schemaform/model/schema.rb")

#
# Defines wrappers for the Language::Placeholders classes.

module Schemaform
module Adapters
module GenericSQL
module Wrappers
class Placeholders
      
   class Wrapper < Wrapper
   end

   
   #
   # Create wrapper classes for all Placeholder classes.
   
   extend Common
   Schemaform::Language::Placeholders.constants(false).each do |constant|
      create_wrapper_class(Schemaform::Language::Placeholders.const_get(constant))
   end


   class Placeholder
      def initialize( context, model )
         super(context, model)
         @production = wrap(model.get_production)
      end
      
      def lay_out()
         @production.lay_out() if @production
      end
   end

   
   
   

end # Placeholders
end # Wrappers
end # GenericSQL
end # Adapters
end # Schemaform
