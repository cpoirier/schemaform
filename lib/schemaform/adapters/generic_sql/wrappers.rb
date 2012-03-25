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
# Defines wrappers for the Model classes.

module Schemaform
module Adapters
module GenericSQL
module Wrappers

   class Wrapper
      include QualityAssurance
      extend  QualityAssurance
      
      def initialize( model, adapter )
         @model   = model
         @adapter = adapter
      end
      
      attr_reader :model, :adapter
   end

   module Common
      def create_wrapper_class( model_class )
         if model_class === Object then
            self.const_defined?(:Wrapper) ? self.const_get(:Wrapper) : Schemaform::Adapters::GenericSQL::Wrappers::Wrapper
         elsif self.const_defined?(model_class.unqualified_name) then
            self.const_get(model_class.unqualified_name)
         else
            self.create_wrapper_class(model_class.superclass).define_subclass(model_class.unqualified_name, self)
         end
      end      
   end

end # Wrappers
end # GenericSQL
end # Adapters
end # Schemaform

["wrappers"].each do |subdir|
   Dir[Schemaform.locate("#{subdir}/*.rb")].each{|path| require path}
end

