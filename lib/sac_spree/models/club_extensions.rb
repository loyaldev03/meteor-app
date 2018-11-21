module Spree
  module ClubExtensions
    def self.included(base)
      # base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def spree(options = {})
        unless @spree_client
          unless [self.api_domain, self.api_password].all?
            raise 'no spree_domain or spree credentials'
          end
          
          @spree_client = Faraday.new(
            url: self.api_domain.url, 
            request: { open_timeout: 20, timeout: 20 }
          ) do |builder|
            builder.request :json
            
            builder.headers.merge!({ 'Accept' => 'application/json', 'X-Spree-Token' => self.api_password })
            
            builder.response :logger, ::Logger.new(STDOUT), bodies: true

            builder.response :json, :content_type => /\bjson$/
            
            builder.response :mashify
            
            builder.adapter :net_http
          end
        end
        @spree_client
      end
    end
  end
end