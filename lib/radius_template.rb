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
			template = self
			
			drops.each do |raw_drop_class|
				drop_name = raw_drop_class.name
				unless @drops.key?(drop_name)
					@drops[drop_name] = raw_drop_class.new
					@drops[drop_name].template = template
					@drops[drop_name].tags.each do |name|
			      define_tag(name) { |tag_binding| @drops[drop_name].render_tag(name, tag_binding) }
			    end
					@drops[drop_name].arrays.each do |name|
			      define_tag(name) do |tag_binding|
			      	array = @drops[drop_name].return_array(name, tag_binding)
							template.build_attributes_for_array(name, array)
							
							main_klass = array.map { |e| e.class.name }.uniq.first
							main_klass = main_klass.downcase.singularize unless main_klass.nil?
							
							content = ''

							array.each do |element|
								tag_binding.locals.set(main_klass, element)
								content << tag_binding.expand
							end

							content
			      end
			    end
			
					@drops[drop_name].objects.each do |name|
			      define_tag(name) do |tag_binding|
			      	object = @drops[drop_name].return_object(name, tag_binding)
							if (object.kind_of?(String) || !object.respond_to?(:to_radius))
								object
							else
								template.build_attributes_for_object(name, object)
								wrap_inside_link(object, tag_binding)
							end
			      end
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
		
		def wrap_inside_link(main_obj, tag)
			main_klass = main_obj.class.name.downcase.singularize
			
			attributes = tag.attributes.clone
			linked = attributes['link'] && attributes['link'] =~ /true/i
			attributes.delete('link')

			content = tag.expand
			
			if content.nil? || content.empty?
				content = main_obj.send(main_obj.to_radius.first)
				linked = true
			end
			
			if linked && !main_obj.nil?
				attributes[:title] = main_obj.send(main_obj.to_radius.first)
				attributes[:href] = url_for({:action => "show", :id => main_obj.to_param, :controller => main_obj.class.name.downcase.pluralize, :only_path => true })
				content_tag(:a, content, attributes)
			else
				content
			end
		end
		
		def build_object_tag(key, main_obj)
			main_klass = main_obj.class.name.downcase.singularize
			
			define_tag(key) do |tag|
				tag.locals.set(main_klass, main_obj)
				wrap_inside_link(main_obj, tag)
			end
			
			build_attributes_for_object(key, main_obj)
		end
		
		def build_attributes_for_object(key, object)
			return unless object.respond_to?(:to_radius)
			
			main_klass = object.class.name.downcase.singularize
			
			object.to_radius.each do |attribute|
				define_tag ("#{key}:#{attribute.to_s}") do |tag|
					obj = tag.locals.get(main_klass).send(attribute) rescue tag.missing! 
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
			
			build_attributes_for_array(key, array)
		end
		
		def build_attributes_for_array(key, array=[])
			main_klass = array.map { |e| e.class.name }.uniq.first
			main_klass = main_klass.downcase.singularize unless main_klass.nil?
			
			define_tag("#{key}:#{main_klass}") do |tag|
				obj = tag.locals.get(main_klass) rescue tag.missing!
				wrap_inside_link(obj, tag)
			end
			
			build_attributes_for_object(key, array.first)
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