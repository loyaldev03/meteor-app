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
    def custom_update

    end
end