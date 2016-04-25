Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.logger = Logger.new("#{Rails.root}/log/delayed_job.log")
Delayed::Worker.logger.level = Logger::DEBUG

Delayed::Worker.class_eval do
  def handle_failed_job_with_notification(job, error)
    handle_failed_job_without_notification(job, error)
    if not error.instance_of? NonReportableException and not %w(test development).include? Rails.env
      Auditory.report_issue(job.name, error, { error: error.inspect, job: job.inspect, handler: job.handler })
    end
  end
  alias_method_chain :handle_failed_job, :notification
end

if Rails.env.production?
  DelayedJobWeb.use Rack::Auth::Basic do |username, password|
    username == 'admin' && password == '2p_D5o0768L9m1j'
  end
end