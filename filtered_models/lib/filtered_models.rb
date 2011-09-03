
# FilteredModels
class ::ActiveRecord::Base

	after_initialize :load_filters


	@@filters = Hash.new
	@@always_filters = {:before => Array.new, :after => Array.new}
	@@except_filters = Hash.new
	@@m_names = nil;


	private 
	
	# Chains a list of method names for a specific one
	# 
	# type = :before, :after
	# _when = :only, :except
	# 
	# i.e: chain_methods_for [:method1, :method2], :filtered_method, :before, :only
	# i.e2: chain_methods_for [:method3], :filtered_method, :before, :except
	# 
	def self.chain_methods_for(methods, for_method, type, _when, &block)
		if(_when == :except)
			@@except_filters[type] = Hash.new if @@except_filters[type].nil?
			@@except_filters[type][for_method] = methods
		end

		if(_when == :only)
			@@filters[for_method] = Hash.new if @@filters[for_method].nil?
			@@filters[for_method][type] = Hash.new if @@filters[for_method][type].nil?
			@@filters[for_method][type][:methods] = methods
			@@filters[for_method][type][:block] = block
		end

		if(_when == :always)
			@@always_filters[type].concat(methods).uniq
		end
	end

	def load_filters(args = nil)

			#puts "CLASS: #{s}
			if(@@m_names.nil?)
				@@m_names= self.class.instance_methods(false).select do |m|
					@@always_filters[:before].index(m).nil? and @@always_filters[:after].index(m).nil?
				end
			end 
			m_names = @@m_names
			#puts "********** Metodos: #{m_names} **************"
		
			# Modify all methods that are not explicitly filtered, so they can be filtered 
			# when a filters has no "_when" 
			m_names.each do |m_name|
				if !self.respond_to?("#{m_name}_with_filter".to_sym)
					#if !@@except_filters[:before].key? m_name.to_sym and !@@except_filters[:after].key? m_name.to_sym
						self.class.send :define_method, "#{m_name}_with_filter".to_sym do |*p|
							@@always_filters[:before].each do |m| self.send m end if !@@always_filters[:before].nil?
							@@except_filters[:before].each do |k,methods| 
								methods.each do |m| 
									self.send m if  m_name != m
								end
							end if !@@except_filters[:before].nil? and !@@except_filters[:before].key? m_name.to_sym 

							self.send "#{m_name}_without_filter".to_sym, *p
							@@always_filters[:after].each do |m| self.send m end if !@@always_filters[:after].nil?
							@@except_filters[:after].each do |k,methods| 
								methods.each do |m| 
									self.send m if m_name != m
								end
							end if !@@except_filters[:after].nil? and !@@except_filters[:after].key? m_name.to_sym 
						end
						self.class.alias_method_chain m_name, :filter
					#end
				end
			end

		@@filters.each { |method, type|
			type.each { |_when, data|
				arr_methods = data[:methods]
	
				if !self.respond_to? "#{method}_with_#{_when}_filter".to_sym
					self.class.send :define_method, "#{method}_with_#{_when}_filter".to_sym do |*p|
						if(_when == :before)
							arr_methods.each do |m| self.send m end
							data[:block].call(self) if !data[:block].nil?
						end 
						self.send "#{method}_without_#{_when}_filter".to_sym, *p
						if(_when == :after)
							arr_methods.each do |m| self.send m end
							data[:block].call(self) if !data[:block].nil?
						end 

					end
					self.class.alias_method_chain method, "#{_when}_filter".to_sym
				end
			}
		}
	end


	public
	def self.before_filter *options , &block
			before_chain = Array.new
			has_cond = false
			options.each { |opt|
				before_chain.push(opt) if !opt.is_a? Hash
				if(opt.is_a? Hash)
					has_cond = true
					opt.each { |_when, methods|
						methods.each { |on_method|
							chain_methods_for(before_chain, on_method, :before, _when, &block)
						}	
					}
				end
			}

		if !has_cond
			chain_methods_for(before_chain, nil, :before, :always)
		end

	end

	def self.after_filter *options 
			chain = Array.new
			has_cond = false
			options.each { |opt|
				chain.push(opt) if !opt.is_a? Hash
				if(opt.is_a? Hash)
					has_cond = true
					opt.each { |_when, methods|
						methods.each { |on_method|
							chain_methods_for(chain, on_method, :after, _when)
						}	
					}
				end
			}

		if !has_cond
			chain_methods_for(chain, nil, :after, :always)
		end
	end

end
