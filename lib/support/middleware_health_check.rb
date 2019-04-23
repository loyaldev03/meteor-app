class MiddlewareHealthCheck
  SUCCESS_RESPONSE = [ 200, { 'Content-Type' => 'text/plain' }, ["Success!".freeze] ]
  PATH = '/healthcheck'.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'.freeze] == PATH
      return SUCCESS_RESPONSE
    else
      @app.call(env)
    end
  end
end
