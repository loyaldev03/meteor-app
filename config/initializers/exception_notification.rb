Rails.application.configure do
  unless %w(test development).include? Rails.env 
    config.middleware.use ExceptionNotification::Rack,
                          :ignore_exceptions => ['ActionController::InvalidAuthenticityToken']

    ExceptionNotification.configure do |config|
      config.add_notifier :pivotal_tracker,
                          project_id: Settings.pivotal_tracker.project_id,
                          api_token:  Settings.pivotal_tracker.token
    end
  end
end