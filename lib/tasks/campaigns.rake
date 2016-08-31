require 'tasks/setup_logger'
require 'tasks/tasks_helpers'

namespace :campaigns do
  desc "Import data from different Transports"
  task :fetch_data  => [:environment, :setup_logger] do
    tall = Time.zone.now
    begin
      TasksHelpers.fetch_campaigns_data
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run campaigns:fetch_data task"
    end
  end
end