module Drupal
  module ClubExtensions
    def self.included(base)
      # base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def drupal
        unless @drupal_client
          unless [self.api_domain, self.api_username, self.api_password].all?
            raise 'no drupal_domain or drupal credentials'
          end

          @drupal_client = Faraday.new(url: self.api_domain.url) do |builder|
            builder.request :json
            builder.request :drupal_auth,
              url: self.api_domain.url,
              username: self.api_username,
              password: self.api_password
            builder.headers.merge!({ 'Accept' => 'application/json' })

            builder.response :json
            builder.response :mashify
            # builder.response :logger, Drupal.logger
            builder.use Drupal::FaradayMiddleware::FullLogger, Drupal.logger

            builder.adapter :net_http
          end
        end

        @drupal_client
      end
    end
  end
end