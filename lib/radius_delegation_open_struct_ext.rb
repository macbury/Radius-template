module Radius
	module DelegatingOpenStructExt
	
		def set(key, value)
			unless object.nil?
        @object.set(key, value)
			end
			@hash[key.to_sym] = value
		end
		
		def get(key)
			val = @hash[key.to_sym]
			
			if val.nil? && !object.nil?
				@object.get(key)
			else
				val
			end
		end
		
	end
end

Radius::DelegatingOpenStruct.send(:include, Radius::DelegatingOpenStructExt)