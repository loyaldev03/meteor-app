class DelayedJob < ActiveRecord::Base


	def reschedule 
		self.run_at = Time.zone.now-3.days	
		self.save	
	end


  def self.datatable_columns
    ['id', 'attempts', 'handler', 'last_error', 'run_at', 'created_at' ]
  end

end
