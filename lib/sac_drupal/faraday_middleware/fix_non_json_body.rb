module Drupal
  module FaradayMiddleware
    class FixNonJsonBody < Faraday::Response::Middleware # hack-around Drupal's bug
      def initialize(app, options = {})
        super(app)
        @options = options
      end

      def on_complete(env)
        env[:response].on_complete do |finished_env|
          body = finished_env[:body]
          if body.is_a?(String)
            finished_env[:body] = JSON.parse(body) rescue {message: body}
          end
        end
      end
    end
  end
end
