module Radius
	module Taggable
	  def self.included(base)
	    base.extend(ClassMethods)
	    base.module_eval do
	      protected
	        def params
	          @params ||= request.parameters unless request.nil?
	        end

	        def request_uri
	          @request_url ||= request.request_uri unless request.nil?
	        end
	    end
	  end

	  def render_tag(name, tag_binding)
	    send "tag:#{name}", tag_binding
	  end
	
		def return_array(name, tag_binding)
	    send "array:#{name}", tag_binding
	  end
		
		def return_object(name, tag_binding)
	    send "object:#{name}", tag_binding
	  end
		
		def tags
			self.methods.grep(/^tag:/).map { |name| name[4..-1] }.sort
		end
		
		def arrays
			self.methods.grep(/^array:/).map { |name| name[6..-1] }.sort
		end
		
		def objects
			self.methods.grep(/^object:/).map { |name| name[7..-1] }.sort
		end
		
		module ClassMethods 
			def register_tag(syntax, &block)
				define_method("tag:#{syntax}", &block)
			end
			
			def register_array(key, &block)
				key = key.gsub("_","-")
				define_method("array:#{key}", &block)
			end
			
			def register_object(key, &block)
				key = key.gsub("_","-")
				define_method("object:#{key}", &block)
			end
		end
	end
	
	class Drop
		include Radius::Taggable
		include ActionController::UrlWriter
		include ActionView::Helpers::TagHelper
		include ActionView::Helpers::AssetTagHelper
		
		attr_accessor :template
		
		def locals=(locals={})
			locals.each do |key, value|
				self.instance_variable_set(:"@#{key}", value)
			end
		end

	end
end