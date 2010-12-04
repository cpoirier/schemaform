#!/usr/bin/env ruby -KU
# =============================================================================================
# SchemaForm
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Contact]   Chris Poirier (cpoirier at gmail dt com)
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



module SchemaForm
module Model
class Field
   
   def initialize( schema)
   
   def >=( lhs )
      assert()
      return FieldIsGTE.new( self, lhs )
   end
   
   
   define_class :Role do
      field :name        , text_type(40)
      field :parents     , {|role| role.find_matching(:RoleInheritance).return_only(:parent => :role)}
      field :ancestors   , {|role| role.find_matching(:RoleInheritance).follow(:RoleInheritance, :role, :parent).return_only(:parent => :role)}
      field :closure     , {|role| relation(:role => role.id) + role.ancestors}
      field :capabilities, {|role| role.closure.join(:RoleCapability).return_only(:capability)}
   end
   
   What is this?
   
   |role| 
     - must be something used to calculate the typing and nature of what is being generated
     - must also generate something that can be be used as that generated thing
     
   
   
   
   
   
   
   


end # Field
end # Model
end # SchemaForm
