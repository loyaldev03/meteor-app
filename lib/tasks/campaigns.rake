require 'tasks/setup_logger'

namespace :campaigns do
  desc "Import data from different Transports"
  task :fetch_data  => [:environment, :setup_logger] do
    tall = Time.zone.now
    begin
      date = Date.current.yesterday
      Club.is_enabled.ids.each do |club_id|
        ['facebook', 'mailchimp'].each do |transport|
          Campaigns::DataFetcherJob.perform_later(club_id, transport, date.to_s)
        end
      end
      Campaigns::NotifyMissingCampaignDaysJob.perform_later((date -1.day).to_s)
      Campaigns::NotifyCampaignDaysWithErrorJob.perform_later
    rescue Exception => e
      Auditory.report_issue("Campaigns::fetch_data", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"      
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run campaigns:fetch_data task"
    end 
  end
end