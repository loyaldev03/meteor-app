Devise::Async.setup do |config|
  config.backend = :delayed_job
  config.queue   = :email_queue
end