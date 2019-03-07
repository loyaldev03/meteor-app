module Spree
  module ClubExtensions
    def self.included(base)
      # base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def spree(options = {})
        unless @spree_client
          raise 'no spree_domain or spree credentials' unless [api_domain, api_password].all?

          @spree_client = Faraday.new(
            url: api_domain.url,
            request: { open_timeout: 20, timeout: 20 }
          ) do |builder|
            builder.request :json

            builder.headers.merge!('Accept' => 'application/json', 'X-Spree-Token' => api_password)

            builder.response :logger, ::Logger.new(STDOUT), bodies: true

            builder.response :json, content_type: /\bjson$/

            builder.response :mashify

            builder.adapter :net_http
          end
        end
        @spree_client
      end
    end
  end
end
