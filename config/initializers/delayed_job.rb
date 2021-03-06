Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay         = 60
Delayed::Worker.max_attempts        = 3
Delayed::Worker.max_run_time        = 5.minutes
Delayed::Worker.read_ahead          = 10
Delayed::Worker.delay_jobs          = !Rails.env.test?
Delayed::Worker.logger              = Logger.new("#{Rails.root}/log/delayed_job.log")
Delayed::Worker.logger.level        = Logger.const_get(Settings.logger_level_for_tasks)

Delayed::Worker.queue_attributes = {
  club_cash_queue:            { priority: 18 },
  elasticsearch_indexing:     { priority: 10 },
  mailchimp_sync:             { priority: 30 },
  exact_target_email:         { priority: 15 },
  mandrill_email:             { priority: 15 },
  lyris_email:                { priority: 15 },
  email_queue:                { priority: 20 },
  drupal_queue:               { priority: 15 },
  generic_queue:              { priority: 40 },
  campaigns:                  { priority: 40 },
  enrollment_delayed_billing: { priority: 10}
}

Delayed::Backend::ActiveRecord.configure do |config|
  config.reserve_sql_strategy = :default_sql
end

if Rails.env.production?
  DelayedJobWeb.use Rack::Auth::Basic do |username, password|
    username == 'admin' && password == '2p_D5o0768L9m1j'
  end
end