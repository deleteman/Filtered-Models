
# FilteredModels
class ::ActiveRecord::Base

	after_initialize :load_filters


	@@filters = Hash.new
	@@always_filters = Hash.new 
	@@except_filters = Hash.new


	private 
	def execute_methods options, current_method
		options.each do |event, methods|
			if !methods.empty? then
				methods.each do |filtered_method|
					if filtered_method == current_method then
						self.send event
					end
				end
			else 
				self.send event
			end

		end
	end

	# Chains a list of method names for a specific one
	# 
	# type = :before, :after
	# _when = :only, :except
	# 
	# i.e: chain_methods_for [:method1, :method2], :filtered_method, :before, :only
	# i.e2: chain_methods_for [:method3], :filtered_method, :before, :except
	# 
	def self.chain_methods_for(methods, for_method, type, _when)
		if(_when == :except)
			@@except_filters[type] = Hash.new if @@except_filters[type].nil?
			@@except_filters[type][for_method] = methods
		end

		if(_when == :only)
			@@filters[for_method] = Hash.new if @@filters[for_method].nil?
			@@filters[for_method][type] = methods;
		end

		if(_when == :always)
			@@always_filters[type] = Array.new if @@always_filters[type].nil?
			@@always_filters[type].concat(methods)
		end
	end

	def load_filters(args = nil)
		class << self
			#method_names = self.instance_methods(false).select do |m|
				#!@@filters.key? m && respond_to?(m.to_sym)
			#end
		
				# Modify all methods that are not explicitly filtered, so they can be filtered 
				# when a filters has no "_when" 
					#puts "*********** methods listing....*************"
			#method_names.each do |m_name|
					#puts m_name
					#puts "Defining method: #{m_name}"
					#define_method "#{m_name}".to_sym do |*p|
						#@@always_filters[:before].each do |m| self.send m end if !@@always_filters[:before].nil?
						#super
						#@@always_filters[:after].each do |m| self.send m end if !@@always_filters[:after].nil?
					#end
					#define_method "#{m_name}_with_filter".to_sym do |*p|
						#if(_when == :before)
							#@@always_filters[:before].each do |m| self.send m end
						#end 
						#self.send "#{m_name}_without_filter".to_sym, *p
						#if(_when == :after)
							#@@always_filters[:after].each do |m| self.send m end
						#end 

					#end
						#if respond_to? m_name
							#alias_method_chain m_name, :filter 
						#end
			#end

		@@filters.each { |method, type|
			
			type.each { |_when, arr_methods|
				define_method "#{method}_with_filter".to_sym do |*p|
					if(_when == :before)
						arr_methods.each do |m| self.send m end
					end 
					self.send "#{method}_without_filter".to_sym, *p
					if(_when == :after)
						arr_methods.each do |m| self.send m end
					end 

				end
				alias_method_chain method, :filter 
			}
		}
		end
	end


	public
	def self.before_filter *options 
			before_chain = Array.new
			has_cond = false
			options.each { |opt|
				before_chain.push(opt) if !opt.is_a? Hash
				if(opt.is_a? Hash)
					has_cond = true
					opt.each { |_when, methods|
						methods.each { |on_method|
							chain_methods_for(before_chain, on_method, :before, _when)
						}	
					}
				end
			}

		#if !has_cond
			#chain_methods_for(before_chain, nil, :before, :always)
		#end

	end

	def self.after_filter *options 
			chain = Array.new
			#has_cond = false
			options.each { |opt|
				chain.push(opt) if !opt.is_a? Hash
				if(opt.is_a? Hash)
					#has_cond = true
					opt.each { |_when, methods|
						methods.each { |on_method|
							chain_methods_for(chain, on_method, :after, _when)
						}	
					}
				end
			}

		#if !has_cond
			#chain_methods_for(before_chain, nil, :before, :always)
		#end

	end


	#def method_missing(current_method, *args)
		#begin
			#super 
		#rescue
			#execute_methods @@before_filter_options, current_method
			#self.send "__#{current_method}".to_sym, *args
			#execute_methods @@after_filter_options, current_method
		#end
	#end
end
