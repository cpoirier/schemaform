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


#
# A helper class that ensures Expression resolution errors are noticed and reported.

module Schemaform
class Schema
class ResolutionSupervisor
   include QualityAssurance
   
   def initialize( schema )
      @schema  = schema
      @entries = []
   end
   
   def monitor( scope, report_worthy = true )
      description = scope_description(scope)
      annotation  = report_worthy ? { :scope => description } : {}
      
      puts "monitoring #{description}"
      assert( !@entries.member?(scope), "detected loop while trying to resolve #{description}" )
      return annotate_errors( annotation ) do
         check( @entries.push_and_pop(scope) { yield() } ) do |result|
            assert( result.exists?, "unable to resolve expression for [#{description}]" )
            type_check( :result, result, Language::ExpressionDefinition::Marker )
            warn_once( "DEBUG: #{description} resolved to #{class_name_for(result.type)} #{type.description}" ) if report_worthy
         end
      end
   end

private
   def class_name_for( object )
      object.class.name.gsub("Schemaform::Definitions::", "")
   end
   
   def scope_description( scope )
      if scope.is_an?(Array) then
         [scope_description( scope.first ), "(" + scope.slice(1..-1).collect{|v| v.to_s}.join(" ") + ")"].join( " " )
      else
         "#{class_name_for(scope)} #{scope.full_name}"
      end
   end
   

end # ResolutionSupervisor
end # Schema
end # Schemaform