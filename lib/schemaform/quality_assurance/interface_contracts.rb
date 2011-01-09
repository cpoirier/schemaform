#!/usr/bin/env ruby -KU
# =============================================================================================
# Schemaform
# A high-level database construction and programming layer.
#
# [Website]   http://schemaform.org
# [Copyright] Copyright 2004-2010 Chris Poirier
# =============================================================================================
# This file is based on rubydbc, a work of Martin Traverso and Brian McCallister, and has been
# modified for use in Schemaform by Chris Poirier.
#
# [Website]   https://github.com/martint/rubydbc/blob/master/lib/dbc.rb
# [Copyright] Copyright 2006-2010 Martin Traverso, Brian McCallister
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
module QualityAssurance
   
   #
   # Provides a basic interface contract system for use in Schemaform.  At present, only pre- and 
   # post-conditions are supported.  Contracts are enforced by default, and must explictly be
   # disabled for use in a production environment.  BUG: How?
   #
   # Examples:
   #
   #    # 
   #    # Assign a set of pre- and/or post-conditions to a new function:
   #
   #    pre( "expected x and y to be different" ) { |x, y| x != y }
   #    post( "expected result to be greater than 0" ) { |x, y, result| result > 0 }
   #    def function( x, y )
   #       return x + y
   #    end
   #
   #    #
   #    # Assign a pre-condition to a specific function (addition):
   #    
   #    pre( :+, "expected Numeric parameter" ) { |rhs| rhs.kind_of?(Numeric) }
   
   module InterfaceContracts
   private 

      #
      # We do all our setup on the fly, when notified about a module or class including us.  The
      # work is easy: we simply add pre() and post() singleton methods to the including module.  
      # However, under the covers, things are somewhat more complex.
      #
      # There are two situations pre() and post() must handle: either the affected method already 
      # exists, and can be immediately altered, or the affected method doesn't already exist, and we
      # have to buffer the condition for application later.  The first situation is trivial: we simply
      # grab the old method and wrap it up in code that calls condition appropriately.  
      #
      # To handle the second situation, we need two things: a list of the pending conditions to be 
      # applied to each non-existant method (which we can build in pre() and post()), and a way to 
      # re-apply the conditions when the method becomes defined.  Fortunately, Ruby provides the 
      # method_added() callback that we can override to process pending conditions on each newly 
      # defined method.
      #
      # Note 1: we want subclasses to inherit our pre() and post() methods from their base classes,
      # and have everything work correctly.  This means we need to override method_added() in each
      # subclass, which we can't do in the included() callback (as that only gets called in the base 
      # class).  In order to make this work, we override method_added() from inside pre() and post(),
      # when we know the actual module being modified.
      #
      # Note 2: any variables we define are shared across all modules that include us.  As such, we 
      # must take steps to ensure we avoid naming collisions and threading issues.  Fortunately, 
      # threading issues are only possible during condition definitions, which should only occur 
      # during class definitions.  Potential BUG: We will assume that Ruby already ensures thread 
      # safety in class definitions (ie. that no two threads will be defining the same class at the 
      # same time).  If that proves untrue, we'll need to add a monitor to serialize writes to our 
      # control variables.
      #
      # Note 3: because pre() and post() are class-level functions, the user's condition code doesn't
      # have an object context, and we need to give it one.  In order to do this, we must convert the
      # condition code to a method, so we can bind it to the object when called.  The same goes for 
      # the wrapper method we create.  In order to avoid polluting the namespace, we just use the 
      # method name for both, replacing the real method with the condition method, and then with the
      # wrapper method.  Each layer calls the previous by way of a variable.
      
   	def self.included( mod )
   		class << mod
   			def pre(method_name = nil, message = nil, &condition)
   			   return if QualityAssurance::checks_disabled?
   				old_method, method_name, message = InterfaceContracts.process_parameters( self, method_name, message )

               if old_method.nil? then
   					InterfaceContracts.buffer_condition( :pre, self, method_name, message, condition )

   				else # See Note 3, above, for an explanation
                  define_method( method_name, &condition )  
                  condition_method = instance_method( method_name )
                  define_method(method_name) do |*args|
                     assert( condition_method.bind(self).call(*args), "Pre-condition #{'\'' + message + '\' ' if message}failed" ) unless QualityAssurance::checks_disabled?
                     old_method.bind(self).call(*args)
                  end
   				end
   			end

   			def post(method_name = nil, message = nil, &condition)
   			   return if QualityAssurance::checks_disabled?
   				old_method, method_name, message = InterfaceContracts.process_parameters( self, method_name, message )
            
               if old_method.nil? then
   					InterfaceContracts.buffer_condition( :post, self, method_name, message, condition )

   				else # See Note 3, above, for an explanation
                  define_method( method_name, &condition )  
                  condition_method = instance_method( method_name )
                  define_method(method_name) do |*args|
   					   result = old_method.bind(self).call(*args)
   					   assert( condition_method.bind(self).call(*(args << result)), "Post-condition #{'\'' + message + '\' ' if message}failed" ) unless QualityAssurance::checks_disabled?
   					   return result
                  end
   				end
   			end
   		end
   	end
   	
   	
      #
      # Given the parameters from a call to pre() or post(), returns the method being replaced (if
      # already defined), and the canonical method name and message.
   
   	def self.process_parameters(object, method_name, message)
	      old_method = nil
	      
   	   if method_name.is_a?(Symbol) then
   	      old_method  = object.instance_method(method_name) if object.method_defined?(method_name)
   	   elsif !method_name.nil? then
   	      message     = method_name
   	      method_name = nil
   	   end
   	   
   	   return old_method, method_name, message
   	end


	   #
	   # Buffers a condition for application to a method when the method is subsequently defined.
	   # If method_name is nil, the condition applies to whatever routine is next defined.
	   
   	def self.buffer_condition( condition_type, mod, method_name, message, condition )
   	   unless defined?(@@interface_contracts__pending)
      	   @@interface_contracts__pending = Hash.new { |hash, key| hash[key] = {} } 
      	end
   	   
   		#
   		# As discussed above, we override the method_added() singleton on mod, if this is
   		# the first time we are buffering for it.  Our override will check for pending
   		# conditions for each added method, and re-call pre() and post() to apply them.
   	   
   	   if !@@interface_contracts__pending.has_key?(mod) then
      		old_method_added = mod.method :method_added
      		new_method_added = lambda do |method_name| 			
      			old_method_added.call( method_name )
      			if @@interface_contracts__pending.has_key?(mod) then
      			   explicit  = @@interface_contracts__pending[mod].delete(method_name)
      			   anonymous = @@interface_contracts__pending[mod].delete(nil)

      			   [explicit, anonymous].compact.flatten.each do |entry|
      					mod.send entry[:type], method_name, entry[:message], &entry[:condition]
   			      end
      			end
      		end
		
      		#
      		# Be sure to hit the module, not the instance, with send(:define_method).  
      		# TODO: find out if mod.class.send() does the same thing in all useful circumstances.
      		
            (class << mod; self; end).send( :define_method, :method_added, new_method_added )
      	end

   	   
   	   #
   	   # With that done, buffer the condition.  We treat the list as a LIFO queue, in order
   	   # to maintain source-order processing of conditions at runtime.
   	   
   	   entry = { :type => condition_type, :message => message, :condition => condition }
   	   
   		@@interface_contracts__pending[mod][method_name] ||= []
   		@@interface_contracts__pending[mod][method_name].unshift( entry )
   	end
   end
   
   
end # QualityAssurance
end # Schemaform
