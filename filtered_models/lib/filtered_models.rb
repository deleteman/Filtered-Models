=begin
# FilteredModels v0.5
# Author: Fernando Doglio
=end
class ::ActiveRecord::Base

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

	public
	def self.before_filter options = {}
		@@before_filter_options = options
	end

	def self.after_filter options={}
		@@after_filter_options = options
	end


	#Here is where the magic happens
	def method_missing(current_method, *args)
		begin
			super 
		rescue
			execute_methods @@before_filter_options, current_method
			self.send "__#{current_method}".to_sym, *args
			execute_methods @@after_filter_options, current_method
		end
	end
end
