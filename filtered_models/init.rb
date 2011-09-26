# Include hook code here
require 'extended_object'
require 'filtered_models'

class ActiveRecord::Base
	extend FilterModels::ClassLevelFilteredMethod

	#There is a difference with the way after_initialize works on rails 2.3.X and rails 3.X
	if Rails::VERSION::STRING.start_with?("3.")
		after_initialize :load_filters
	else
		def after_initialize 
			load_filters
		end

	end

	def is_accessor_method? method_name
		#For rails 2.X we get the setters like this: MEHTOD_NAME=
		method_name = method_name.to_s.sub(/=/,"").to_sym
		if @@accessors.include?(method_name) || @@getters.include?(method_name) || @@setters.include?(method_name)
			true
		else
			false
		end
	end

	

end
