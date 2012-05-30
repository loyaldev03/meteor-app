module Wordpress
  module ClubExtensions
    def self.included(base)
      # base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def wordpress
        unless @wordpress_client
          unless [self.api_domain, self.api_username, self.api_password].all?
            raise 'no wordpress_domain or wordpress credentials'
          end

          @wordpress_client = Faraday.new(url: self.api_domain.url) do |builder|
            builder.request :json
            builder.request :wordpress_auth,
              url: self.api_domain.url,
              username: self.api_username,
              password: self.api_password
            builder.headers.merge!({ 'Accept' => 'application/json' })

            builder.response :json
            builder.response :mashify
            # builder.response :logger, Drupal.logger
            builder.use Wordpress::FaradayMiddleware::FullLogger, Drupal.logger

            builder.adapter :net_http
          end
        end

        @wordpress_client
      end
    end
  end
end
