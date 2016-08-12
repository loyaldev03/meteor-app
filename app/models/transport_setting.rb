class TransportSetting < ActiveRecord::Base
  belongs_to :club

  before_validation :set_data

  validates_presence_of :transport
  validates :fb_client_id, :fb_client_secret, :fb_access_token, presence: true, if: "transport == 'facebook'"
  validates :mc_api_key, presence: true, if: "transport == 'mailchimp'"

  attr_accessor :fb_client_id, :fb_client_secret, :fb_access_token
  attr_accessor :mc_api_key

  enum transport: {
    facebook:   0,
    mailchimp:  1,
    # twitter:    2,
    # adwords:    3
  }

  serialize :settings, JSON

  def self.datatable_columns
    [ 'id', 'transport', 'settings' ]
  end

  def parse_settings!
    case transport
    when 'facebook'
      self.fb_client_id = settings['client_id']
      self.fb_client_secret = settings['client_secret']
      self.fb_access_token = settings['access_token']
    when 'mailchimp'
      self.mc_api_key = settings['api_key']
    end 
  end

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
