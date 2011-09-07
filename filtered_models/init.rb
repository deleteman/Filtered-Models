# Include hook code here
require 'filtered_models'

class ActiveRecord::Base
	extend FilterModels::ClassLevelFilteredMethod

	after_initialize :load_filters
end