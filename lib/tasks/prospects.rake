require 'tasks/tasks_helpers'

namespace :prospects do

  task :sync_to_exact_target => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/sync_prospect_to_exact_target.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
	    base = Prospect.where("date(created_at) = ?", Time.zone.now.to_date-1.day)
	    base.find_in_batches do |group|
	      tz = Time.zone.now
	      group.each_with_index do |prospect,index|
	        begin
	          Rails.logger.info "  *[#{index+1}] processing prospect ##{prospect.id}"
 						prospect.exact_target_after_create_sync_to_remote_domain if defined?(SacExactTarget::ProspectModel)
	        rescue Exception => e
	          Auditory.report_issue("Prospect::SyncExactTarget", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :prospect => prospect.inspect })
	          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"        
	        end
	        Rails.logger.info "    ... took #{Time.zone.now - tz} for prospect ##{prospect.id}"
	      end
	    end
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall} to run prospects:sync_to_exact_target task"
    end 
  end

end