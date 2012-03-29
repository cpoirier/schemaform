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
      
      def initialize( context, model )
         @model = model
         if context.is_an?(Adapter) then
            @context = nil
            @adapter = context
         else
            @context = context
            @adapter = context.adapter
         end
      end
      
      attr_reader :model, :adapter, :context
      
      def wrap( model )
         case model
         when Schemaform::Model::Component
            if @model.is_a?(Schemaform::Model::Component) || @model.is_a?(Schemaform::Model::Schema) then
               @adapter.model_wrappers_module.const_get(model.class.unqualified_name).new(self, model)
            else
               model
            end
         when Schemaform::Language::Productions::Production
            @adapter.production_wrappers_module.const_get(model.class.unqualified_name).new(self, model)
         when Schemaform::Language::Placeholders::Placeholder
            @adapter.placeholder_wrappers_module.const_get(model.class.unqualified_name).new(self, model)
         else
            model
         end
      end
      
      def each_context()
         result  = nil
         current = @context
         while current
            result  = yield(current)
            current = current.context
         end      
         result
      end

      def find_context( first = true, default = nil )
         match = default
         each_context do |current|
            if yield(current) then
               match = current
               break if first
            end
         end
         match
      end
      
      def lay_out()
      end      
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

