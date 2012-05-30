module Wordpress
  module FaradayMiddleware
    # Taken from the standard Logger middleware, added body
    class FullLogger < Faraday::Response::Middleware
      extend Forwardable

      def initialize(app, logger = nil)
        super(app)
        @logger = logger || begin
          require 'logger'
          ::Logger.new(STDOUT)
        end
      end

      def_delegators :@logger, :debug, :info, :warn, :error, :fatal

      def call(env)
        info "#{env[:method]} #{env[:url].to_s}"
        debug('request') { dump_headers env[:request_headers] }
        debug('body') { env[:body] }
        super
      end

      def on_complete(env)
        info('Status') { env[:status].to_s }
        debug('response') { dump_headers env[:response_headers] }
        debug('body') { env[:response].body }
      end

      private

      def dump_headers(headers)
        headers.map { |k, v| "\t#{k}: #{v.to_s}" }.join("\n")
      end
    end
  end
end
