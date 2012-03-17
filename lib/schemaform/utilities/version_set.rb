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


#
# Tracks a set of versions of something (generally Schemas).

module Schemaform
class VersionSet

   def initialize( name )
      @name     = name
      @versions = {}
      @current  = nil
   end
   
   attr_reader :name
   
   def current()
      @current ? @versions[@current] : nil
   end
   
   def []( version )
      if version.nil? then
         @current ? @versions[@current] : nil
      else
         @versions.fetch(version, nil)
      end
   end
   
   def []=( version, object )
      @versions[version] = object
   end
   
   def version?( version )
      if version.nil? then
         @current.exists?
      else
         @versions.member?(version)
      end
   end
   
   alias member? version?


end # VersionSet
end # Schemaform
