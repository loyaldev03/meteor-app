class TransportSetting < ActiveRecord::Base
  belongs_to :club

  attr_accessor :fb_client_id, :fb_client_secret, :fb_access_token
  attr_accessor :mc_api_key

  before_validation :set_data

  enum transport: {
    facebook:   0,
    mailchimp:  1,
    # twitter:    2,
    # adwords:    3
  }

  serialize :settings, JSON

  private
    def set_data
      case transport
      when 'facebook'
        self.settings = { client_id: fb_client_id, client_secret: fb_client_secret, access_token: fb_access_token }
      when 'mailchimp'
        self.settings = { api_key: mc_api_key }
      when 'twitter', 'adwords'
        self.settings = nil
      end
    end
end
