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
# Base class for all Relation models.

module Schemaform
module Expressions
class Relation < Expression
   
   def initialize( tuple, keys = [] )
      @tuple = tuple
      @keys  = keys
   end
   
   
   #
   # Returns a relation containing a subset of the rows in this one.
   
   def find( &block )
      
   end
   
   alias find where
   
   
   #
   # Returns a subset of the target relation containing those records that match this
   # record's key.  If the target relation contains more than one reference to this type,
   # you must specify which to consider.  If the target relation contains no reference to
   # this type, of this type doesn't have a key, the empty set will be returned.
   
   def find_matching( target, id_field = nil )
   end


   #
   # Returns a relation containing a subset of the columns in this one, possibly renamed.
   # Note: due to the way Ruby works, you should put all your renames at the end of the list.
   
   def project( *list )
   end
   
   alias project return_only
      
   
   #
   # Returns a relation containing a subset of the columns in this one -- all except the ones
   # you list here.
   
   def project_away( *list )
   end
   
   alias project_away return_all_except
   
   
   #
   # Returns a relation containing all records from this and another relation (union).
   
   def +( rhs )
   end
   
   
   #
   # Returns a relation containing all records from this relation not in another (difference).
   
   def -( rhs )
   end
   
   
   #
   # Returns a relation contain all records from this relation also in another (intersection).
   
   def &( rhs )
   end
   
   
   #
   # Returns a relation containing the join of this relation and another along all common
   # fields.
   
   def join( rhs )
   end
   
   
   #
   # Returns a relation containing a transitive closure of the target relation, starting
   # from records in this one.
   
   def follow( target, from_field, to_field )
   end
   
   
   #
   # Returns a relation containing one additional column, calculated record-by-record
   # by your block.
   #
   # Example:
   #   relation = all(:class).add(:new_column){|record| record.old_column * 3}
   
   def add( name, &description )
   end
   
   
   #
   # Returns a relation containing one additional column, calculated by calling your
   # block once for each matching record within each key set, inject() style.  Note, 
   # if there is a specific add_*() routine that meets your needs, you should use it, 
   # as it will use native database support where possible.
   # 
   # Example -- calculating a sum:
   #   records = all(:class).where{|row| row.criteria_column == 10}
   #   keys    = records.project(:key_column)
   #
   #   results = keys.add_summary(:sum_column, records, 0) {|value, record| value + record.value_column}
   #     # OR
   #   results = keys.add_sum(:sum_column, records, :value_column)
   
   def add_summary( name, over_relation, seed = 0 )
   end
   
   def add_count( name, over_relation, field )
   end

   def add_avg( name, over_relation, field )
   end

   def add_max( name, over_relation, field )
   end

   def add_min( name, over_relation, field )
   end

   def add_sum( name, over_relation, field )
   end

   def add_concatenation( name, over_relation, field )
   end
   
   
   
   
   
   # NYI: prefix, prefix except, generalized header math?
   # NYI: transitive closure with summarize
   
   
end # Relation
end # Expressions
end # Schemaform
