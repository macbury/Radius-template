module Radius
	class Template < Context
		include ActionController::UrlWriter
		include ActionView::Helpers::TagHelper
		
		def initialize(tag_prefix,locals = {}, drops = [])
			super()
			@tag_prefix = tag_prefix
			@drops = {}
			@locals = {}
			
			self.locals = locals
			self.drops = drops
		end
		
		def drops=(drops=[])
			drops.each do |raw_drop_class|
				drop_name = raw_drop_class.name
				unless @drops.key?(drop_name)
					@drops[drop_name] = raw_drop_class.new
					@drops[drop_name].tags.each do |name|
			      define_tag(name) { |tag_binding| @drops[drop_name].render_tag(name, tag_binding) }
			    end
				end

				@drops[drop_name].locals = @locals
			end
		end

		def locals=(locals={})
			@locals.merge!(locals)
			@locals.each do |key, value|
				if value.respond_to?(:to_radius)
					build_object_tag(key.to_s, value)
				elsif value.kind_of?(Array)
					build_enum_tags(key,value)
				else
					define_tag key.to_s, :for => value
				end
			end

			@drops.each { |name, drop| drop.locals = @locals }
		end
		
		def build_object_tag(key, main_obj)
			main_klass = main_obj.class.name.downcase.singularize
			
			define_tag(key) do |tag|
				attributes = tag.attributes.clone
				linked = attributes['link'] && attributes['link'] =~ /true/i
				attributes.delete('link')
				tag.locals.set(main_klass, main_obj)
				content = tag.expand
				
				if content.nil? || content.empty?
					content = main_obj.send(main_obj.to_radius.first)
					linked = true
				end
				
				if linked && !main_obj.nil?
					attributes[:href] = url_for({:action => "show", :id => main_obj.to_param, :controller => main_obj.class.name.downcase.pluralize, :only_path => true })
					content_tag :a, content, attributes
				else
					content
				end
			end
			
			main_obj.to_radius.each do |attribute|
				define_tag ("#{key}:#{attribute.to_s}") do |tag|
					begin
						obj = tag.locals.get(main_klass).send(attribute)
					rescue 
						tag.missing!
					end
				end
			end
		end
		
		def build_enum_tags(key, array=[])
			key = key.to_s.pluralize.downcase
			main_klass = array.map { |e| e.class.name }.uniq.first
			main_klass = main_klass.downcase.singularize unless main_klass.nil?
			
			
			define_tag(key) do |tag|
				content = ''
				
				array.each do |element|
					tag.locals.set(main_klass, element)
					content << tag.expand
				end

				content
			end
			
			return if array.size == 0 || !array.first.respond_to?(:to_radius)
			
			define_tag("#{key}:#{main_klass}") do |tag|
				linked = tag['link'] && tag['link'] =~ /true/i
				obj = tag.locals.get(main_klass) rescue tag.missing!
				content = tag.expand
				
				if content.nil? || content.empty?
					content = obj.send(obj.to_radius.first)
					linked = true
				end
				
				if linked && !obj.nil?
					#tag.attributes.delete('link')
					tag.attributes[:href] = url_for({:action => "show", :id => obj.to_param, :controller => obj.class.name.downcase.pluralize, :only_path => true })
					content_tag :a, content, tag.attributes
				else
					content
				end
			end
			
			array.first.to_radius.each do |attribute|
				define_tag ("#{key}:#{main_klass}:#{attribute.to_s}") do |tag|
					begin
						obj = tag.locals.get(main_klass).send(attribute)
					rescue 
						tag.missing!
					end
				end
			end
		end

		def tag_missing(tag, attr, &block)
			"<strong>ERROR: </strong> undefined tag: #{tag} attributes: #{attr.inspect}"
		end

		def locals
			@locals
		end

		def parser
			@parser ||= Radius::Parser.new(self, :tag_prefix => @tag_prefix)
			@parser
		end

		def parse(input)
			parser.parse(input)
		end

	end
end