workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

before_fork do
  require 'puma_stats_logger'
  if defined?(PumaStatsLogger)
    Rails.logger.debug "Running PumaStatsLogger"
    PumaStatsLogger.run
  else
    Rails.logger.debug "NOT Running PumaStatsLogger"
  end
end

on_worker_boot do
  Rails.logger.debug "puma on_worker_boot"
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end