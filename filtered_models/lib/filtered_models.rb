
=begin
Module with all methods for the Filtered Models plugin.

- FilteredModels::FilterDataMod -> Contains the definition for the "data" class attribute and the "FilterData" class, which contains all information for each filter.
- FilteredModels::ClassLevelFilteredMethod -> Contains all class level methods to be added to the ActiveRecord class
- FilteredModels::InstanceLevelFilterMethods -> Contains all instance level methods to be added to the ActiveRecord class
=end
module FilterModels

module FilterDataMod
	@@data = {}
	class FilterData
		attr_accessor :filters, :always_filters, :except_filters, :m_names

		def initialize
			@filters = Hash.new
			@always_filters = {:before => Array.new, :after => Array.new}
			@except_filters = Hash.new
			@m_names = nil;
		end


	end

end

module ClassLevelFilteredMethod


	include FilterDataMod

	#Redefine the extended callback, to include the instance level methods after this module has been extended
	def self.extended(base)
		base.send :include, InstanceLevelFilterMethods
	end

	private 
	
	# Chains a list of method names for a specific one
	# 
	# type = :before, :after
	# _when = :only, :except
	# 
	# i.e: chain_methods_for [:method1, :method2], :filtered_method, :before, :only
	# i.e2: chain_methods_for [:method3], :filtered_method, :before, :except
	# 
	def chain_methods_for(methods, for_method, type, _when, &block)
		@@data[self.name] = FilterData.new if @@data[self.name].nil?
		if(_when == :except)
			@@data[self.name].except_filters[type] = Hash.new if @@data[self.name].except_filters[type].nil?
			@@data[self.name].except_filters[type][for_method] = methods
		end

		if(_when == :only)
			@@data[self.name].filters[for_method] = Hash.new if @@data[self.name].filters[for_method].nil?
			@@data[self.name].filters[for_method][type] = Hash.new if @@data[self.name].filters[for_method][type].nil?
			@@data[self.name].filters[for_method][type][:methods] = methods
			@@data[self.name].filters[for_method][type][:block] = block
		end

		if(_when == :always)
			@@data[self.name].always_filters[type].concat(methods).uniq
		end
	end

	

	public
	def before_filter *options , &block
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

	def after_filter *options 
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


module InstanceLevelFilterMethods
	include FilterDataMod

	private

	def get_filtered_method_name mname
		mname = mname.to_s
		if(!mname.index("=").nil?)
			"#{mname.sub("=", "")}_with_filter="
		else
			mname + "_with_filter"	
		end
	end



	def get_unfiltered_method_name mname
		mname = mname.to_s
		if(!mname.index("=").nil?)
			"#{mname.sub("=", "")}_without_filter="
		else
			mname + "_without_filter"	
		end
	end



	#Creates all methods needed for the filters to take place. This method is called on the "after_initialize" event, triggered by the AR class.
	def load_filters(args = nil)

			@@data[self.class.name] = FilterData.new if @@data[self.class.name].nil?
			if(@@data[self.class.name].m_names.nil?)
				@@data[self.class.name].m_names= self.class.instance_methods(false).select do |m|
					@@data[self.class.name].always_filters[:before].index(m).nil? and @@data[self.class.name].always_filters[:after].index(m).nil?
				end
			end 
			m_names = @@data[self.class.name].m_names
		
			# Modify all methods that are not explicitly filtered, so they can be filtered 
			# when a filters has no "_when" 
			m_names.each do |m_name|
				if !self.respond_to?("#{m_name}_with_filter".to_sym)
						self.class.send :define_method, get_filtered_method_name(m_name).to_sym do |*p|
							@@data[self.class.name].always_filters[:before].each do |m| self.send m end if !@@data[self.class.name].always_filters[:before].nil?
							@@data[self.class.name].except_filters[:before].each do |k,methods| 
								methods.each do |m| 
									self.send m if  m_name != m
								end
							end if !@@data[self.class.name].except_filters[:before].nil? and !@@data[self.class.name].except_filters[:before].key? m_name.to_sym 

							original_return = self.send get_unfiltered_method_name(m_name).to_sym, *p
							@@data[self.class.name].always_filters[:after].each do |m| self.send m end if !@@data[self.class.name].always_filters[:after].nil?
							
							if !@@data[self.class.name].except_filters[:after].nil? and !@@data[self.class.name].except_filters[:after].key? m_name.to_sym
								@@data[self.class.name].except_filters[:after].each do |k,methods| 
									methods.each do |m| 
										self.send m if m_name != m
									end
								end  
							else 
								original_return
							end
						end
						self.class.alias_method_chain m_name, :filter
				end
			end

		@@data[self.class.name].filters.each { |method, type|
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

end

end