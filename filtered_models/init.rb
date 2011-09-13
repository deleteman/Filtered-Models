# Include hook code here
require 'filtered_models'

class ActiveRecord::Base
	extend FilterModels::ClassLevelFilteredMethod

	
	if !Rails::VERSION::STRING.start_with?("2.")
		after_initialize :load_filters
	else
		def after_initialize 
			load_filters
		end

	end

end
