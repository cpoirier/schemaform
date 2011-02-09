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



module Schemaform
module Adapters
   extend QualityAssurance
   
   def self.adapter_class_for( connection_url, fail_if_missing = true )
      @@selectors = [] unless defined?(@@selectors) && @@selectors.is_an?(Array)
      @@selectors.each do |selector|
         return selector.adapter_class if selector.matches?(connection_url)
      end
      
      fail( "unable to find adapter for #{connection_url}" ) if fail_if_missing
      return nil
   end

   def self.register( adapter_class, url_pattern = nil, &url_tester )
      @@selectors = [] unless defined?(@@selectors) && @@selectors.is_an?(Array)
      if url_pattern.nil? then
         assert( block_given?, "expected either a pattern or a block" )
         @@selectors << BlockBasedSelector.new( adapter_class, &url_tester )
      else
         @@selectors << PatternBasedSelector.new( adapter_class, url_pattern )
      end
   end
   
   


   # ==========================================================================================
   #                                          Selectors
   # ==========================================================================================

   class Selector
      include QualityAssurance
      attr_reader :adapter_class
      def initialize( adapter_class )
         @adapter_class = adapter_class
      end
      
      def matches?( connection_url )
         fail_unless_overriden( self, :matches? )
      end
   end
   
   class PatternBasedSelector < Selector
      def initialize( adapter_class, url_pattern )
         super( adapter_class )
         @url_pattern = url_pattern
      end
      
      def matches?( connection_url )
         !!(@url_pattern =~ connection_url)
      end
   end
   
   class BlockBasedSelector < Selector
      def initialize( adapter_class, &block )
         super( adapter_class )
         @tester = block
      end
      
      def matches?( connection_url )
         !!(@tester.call(connection_url))
      end
   end
      
end # Adapters
end # Schemaform


Dir[Schemaform.locate("adapters/*/adapter.rb")].each do |path| 
   require path
end
