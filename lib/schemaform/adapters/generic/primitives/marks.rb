#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2011 Chris Poirier
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


module Schemaform
module Adapters
module Generic


   #
   # Base class for things that configure a Field in some way. Override Mark::build() if you need
   # parameters.

   class FieldMark
      include QualityAssurance
      extend  QualityAssurance
   
      def self.build()
         @@instances[self] ||= new()
      end
   
      @@instances = {}
      
   end # FieldMark
   
   
   class GeneratedMark  < FieldMark ; end
   class PrimaryKeyMark < FieldMark ; end
   class RequiredMark   < FieldMark ; end
   
   class ReferenceMark  < FieldMark
      
      def self.build( table, deferrable = false )
         new(table, deferrable)
      end
      
      def initialize( table, deferrable = false )
         type_check(:table, table, Table)
         @table      = table
         @deferrable = deferrable
      end

      def table()       ; @table      ; end
      def deferrable?() ; @deferrable ; end
   end
  
   class StructuralLink < ReferenceMark 
      def self.build( table, is_direct_parent = false )
         new(table, is_direct_parent)
      end
      
      def initialize( table, is_direct_parent = false )
         super( table )
         @is_direct_parent = is_direct_parent
      end
      
      def direct_parent?()
         @is_direct_parent
      end
   end 
   
end # Generic
end # Adapters
end # Schemaform

