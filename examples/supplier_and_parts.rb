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


#
# An example Schema definition: the classic Suppliers and Parts database.

def example_supplier_and_parts_schema()
   Schemaform.define :SuppliersAndParts do
   end
end



#
# If called directly, set up the environment and run some tests.

if $0 == __FILE__ then
   
   require "../lib/schemaform.rb"
   schema     = example_supplier_and_parts_schema()
   connection = schema.connect( ARGV.empty? ? "sqlite:///tmp/example_supplier_and_parts.db" : ARGV.shift )


end