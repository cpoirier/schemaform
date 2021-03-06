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

require Schemaform.locate("placeholder.rb")


module Schemaform
module Language
module Placeholders
class LiteralList < Placeholder
   
   def initialize( *members )
      @members = members

      member_type = Model::Schema.current.unknown_type
      members.each do |member|
         member_type = member_type.best_common_type(member.get_type)
      end
      
      super(Model::Schema.current.build_list_type(member_type))
   end
   
   def method_missing( symbol, *args, &block )
      super
   end
   
   
end # LiteralList
end # Placeholders
end # Language
end # Schemaform

