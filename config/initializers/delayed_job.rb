Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.delay_jobs = !Rails.env.test?

Delayed::Worker.class_eval do
  def handle_failed_job_with_notification(job, error)
    handle_failed_job_without_notification(job, error)
    Auditory.report_issue(job.name, error, { job: job.inspect, handler: job.handler })
  end
  alias_method_chain :handle_failed_job, :notification
end