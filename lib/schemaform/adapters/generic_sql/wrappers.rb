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

module Schemaform
module Adapters
module GenericSQL
class Wrappers
      
   #
   # Called by Model::*.wrap(adapter) to retrieve the corresponding wrapper object from
   # the adapter. You can subclass Wrappers in your specific Adapter, create subclasses of 
   # individual wrapper classes, and this routine will continue to work (as long as the
   # names stay the same).
   
   def self.wrap( model_object, adapter )
      adapter.wrappers.fetch!(model_object) do
         self.const_get(model_object.class.unqualified_name).new(model_object, adapter)
      end
   end




   # =======================================================================================
   #                                   Model Class Wrappers
   # =======================================================================================

   #
   # Creates a single (empty) class that corresponds in hierarchy to a class from the Model.
   
   def self.create_wrapper_class( model_class )
      super_class = if model_class.superclass === Object then
         Object
      elsif self.const_defined?(model_class.superclass.unqualified_name) then
         self.const_get(model_class.superclass.unqualified_name)
      else
         self.create_wrapper_class(model_class.superclass)
      end
      
      super_class.define_subclass(model_class.unqualified_name, self) do 
         def initialize( model, adapter )
            @model   = model
            @adapter = adapter
         end
         
         attr_reader :model, :adapter
         
         def method_missing( symbol, *args, &block )
            @model.send(symbol, *args, &block)
         end

         def respond_to?(symbol)
            super || @model.respond_to?(symbol)
         end

      end
   end
   
   #
   # Create wrapper classes for all Model classes.
   
   Model.constants(false).each do |constant|
      create_wrapper_class(Model.const_get(constant))
   end

end # Wrappers
end # GenericSQL
end # Adapters
end # Schemaform
