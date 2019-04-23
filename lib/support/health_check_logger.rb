class HealthCheckLogger < Rails::Rack::Logger
  def initialize(app, opts = {})
    @app = app
    @opts = opts
    super
  end

  def call(env)
    if env['PATH_INFO'] == "/healthcheck"
      Rails.logger.silence do
        @app.call(env)
      end
    else
      super(env)
    end
  end
end
