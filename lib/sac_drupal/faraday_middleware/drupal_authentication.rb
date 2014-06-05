module Drupal
  module FaradayMiddleware
    class DrupalAuthentication < Faraday::Middleware
      class AuthError < StandardError; end
      SESSION_PATH = '/api/system/connect'.freeze
      LOGIN_PATH = '/api/user/login'.freeze
      TOKEN_PATH = '/services/session/token'.freeze

      def initialize(app, options)
        super(app)
        @options = options
      end

      def call(env)
        cookie, res = false, nil
        Drupal.logger.info "logout var #{@options[:logout]} - #{self.cookie} - #{@options[:logout]}"
        if self.cookie and not @options[:logout]
          Drupal.logger.debug " ** using existing cookie for #{@options[:url]}: #{self.cookie}"
          cookie = true
        else
          self.regenerate_cookie!
        end

        env[:request_headers]['Cookie'] = self.cookie
        env[:request_headers]['X-CSRF-Token'] = self.generate_token
        old_body = env[:body] # lets store the first body. because it will be overwritten after call/token regeneration

        time_elapsed = Benchmark.ms do
          res = @app.call(env)
        end
        Drupal.logger.info "Drupal::#{env[:url]} took #{time_elapsed}ms"
  
        if [401, 403].include?(res.status) && cookie # retry if cookie is invalid
          Drupal.logger.debug(" ** invalidating %.2f seconds-old cookie. old body #{old_body.inspect}" % self.cookie_age)
          self.invalidate_cookie!
          self.regenerate_cookie!

          env[:request_headers]['Cookie'] = self.cookie
          env[:request_headers]['X-CSRF-Token'] = self.generate_token
          env[:body] = old_body
          time_elapsed = Benchmark.ms do
            res = @app.call(env)
          end
          Drupal.logger.info "Drupal::#{env[:url]} took #{time_elapsed}ms"
        end
        res
      end

      def invalidate_cookie!
        store.delete(@options[:url])
      end

      def regenerate_cookie!
        Drupal.logger.debug " ** Generating cookie for #{@options[:url]}"
        sid = self.generate_session_id!
        self.generate_cookie! sid
      end

      def cookie=(cookie)
        store[@options[:url]] = { body: cookie, created_at: Time.now }
      end

      def cookie
        store && store[@options[:url]] && store[@options[:url]][:body]
      end

      def generate_token
        conn = simple_connection
        conn.headers['Cookie'] = self.cookie
        res = conn.get TOKEN_PATH
        if res.status == 200
          res.body.strip
        else
          Drupal.logger.error AuthError.new("HTTP #{res.status} when getting token") 
          nil
        end
      rescue Exception => e
        Auditory.report_issue("FaradayMiddleware::DrupalAuthentication::GenerateToken", e.to_s, { drupal_response: res.to_s })
      end

      def cookie_age
        store && store[@options[:url]] && (Time.now - store[@options[:url]][:created_at])
      end

      def store
        Thread.current[:drupal_cookies] ||= {}
        Thread.current[:drupal_cookies]
      end

      def generate_session_id!
        res = simple_connection.post SESSION_PATH
        raise AuthError.new("HTTP #{res.status} when getting session id") unless res.status == 200
        JSON.parse(res.body)['sessid']
      end

      def generate_cookie!(sessid)
        body = { 
          sessid: sessid, 
          username: @options[:username], 
          password: @options[:password]
        }.map { |tuple| tuple * '=' } * '&'
        res = simple_connection.post LOGIN_PATH, body

        raise AuthError.new("HTTP #{res.status} when getting auth cookie") unless res.status == 200

        json = JSON.parse res.body
        self.cookie = '%s=%s' % [json['session_name'], json['sessid']]

        Drupal.logger.debug " ** [#{$$} #{Time.now.to_s(:db).gsub(/[\-\:]/, '')} ] got new cookie for #{@options[:url]}: #{self.cookie}"
        self.cookie
      end

      def auth_headers
        headers = {
          'Content-Type' => 'application/x-www-form-urlencoded', 
          'Accept'       => 'application/json'
        }
        # This is stoneacre:stoneacre Base64 encoded using http://www.motobit.com/util/base64-decoder-encoder.asp
        headers['Authorization'] = 'Basic c3RvbmVhY3JlOnN0b25lYWNyZQ=='
        headers    
      end

      def simple_connection
        Faraday.new(url: @options[:url]) do |http| 
          http.headers = auth_headers
          http.use Drupal::FaradayMiddleware::FullLogger, Drupal.logger
          http.adapter :net_http 
        end
      end
    end
  end
end
