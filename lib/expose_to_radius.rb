module ExposeToRadius
	module ClassMethods
		
		def radius_attr_accessible(*attributes)
			unless attributes.kind_of?(Array)
				attributes = [attributes]
			end
			
			define_method("to_radius") do
				attributes
			end
		end
		
	end
	
	def self.included(receiver)
		receiver.extend         ClassMethods
	end
end

if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, ExposeToRadius)
end