# #!/usr/bin/env ruby
# # =============================================================================================
# # Schemaform
# # A DSL giving the power of spreadsheets in a relational setting.
# #
# # [Website]   http://schemaform.org
# # [Copyright] Copyright 2004-2012 Chris Poirier
# # [License]   Licensed under the Apache License, Version 2.0 (the "License");
# #             you may not use this file except in compliance with the License.
# #             You may obtain a copy of the License at
# #             
# #                 http://www.apache.org/licenses/LICENSE-2.0
# #             
# #             Unless required by applicable law or agreed to in writing, software
# #             distributed under the License is distributed on an "AS IS" BASIS,
# #             WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# #             See the License for the specific language governing permissions and
# #             limitations under the License.
# # =============================================================================================
# 
# require Schemaform.locate("maps.rb")
# 
# 
# module Schemaform
# module Adapters
# module GenericSQL
# 
#    
#    #
#    # The base class for things that map Model elements into the adapter.
# 
#    class Map
#       def build()
#       end
#    end
#    
#    
#    class SchemaMap < Map
#    end 
#    
#    
#    class EntityMap < Map
#    end
#    
#       
#    class TupleMap < Map
#    end
# 
# 
#    class AttributeMap < Map
#    end
#    
#    
#    
#    
#    #
#    # The base class for maps of things that take up space.
#    
#    class StorageMap < Map
#    end
# 
#    
#    class ScalarMap < StorageMap
#    end
#    
#    class CollectionMap < ScalarMap
#    end
#    
#    class ListMap < CollectionMap
#    end
#    
#    class EnumerationMap < ListMap
#    end
#    
#    class SetMap < CollectionMap
#    end
#    
#    class RelationMap < SetMap
#       def build()
#          @heading_map.build()
#       end      
#    end
#    
#    
#    
# 
# end # GenericSQL
# end # Adapters
# end # Schemaform
