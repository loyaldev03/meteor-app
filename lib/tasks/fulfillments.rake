require 'tasks/tasks_helpers'

namespace :fulfillments do
  desc "Check if there have been shipping cost reports uploaded to be processed"
  task :process_shipping_cost_reports => [:environment, :setup_logger] do
    TasksHelpers.process_shipping_cost
  end

end