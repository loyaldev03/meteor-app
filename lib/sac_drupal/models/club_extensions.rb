module Drupal
  module ClubExtensions
    def self.included(base)
      base.belongs_to :drupal_domain,
        class_name:  'Domain',
        foreign_key: 'drupal_domain_id'

      # base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def drupal
        unless @drupal_client
          unless [self.drupal_domain, self.drupal_username, self.drupal_password].all?
            raise 'no drupal_domain or drupal credentials'
          end

          @drupal_client = Faraday.new(url: self.drupal_domain.url) do |builder|
            builder.request :json
            builder.request :drupal_auth,
              url: self.drupal_domain.url,
              username: self.drupal_username,
              password: self.drupal_password
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