Delayed::Worker.logger = Logger.new("#{Rails.root}/log/delayed_job.log")
Delayed::Worker.logger.level = Logger::DEBUG
Delayed::Worker.class_eval do
  def handle_failed_job_with_notification(job, error)
    handle_failed_job_without_notification(job, error)
    Auditory.report_issue(job.name, error, { job: job.inspect, handler: job.handler })
  end
  alias_method_chain :handle_failed_job, :notification
end