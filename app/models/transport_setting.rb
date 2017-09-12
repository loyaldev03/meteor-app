class TransportSetting < ActiveRecord::Base
  belongs_to :club

  store :settings, accessors: [ 
    :client_id, 
    :client_secret, 
    :access_token,
    :api_key,
    :tracking_id,
    :container_id,
    :url, 
    :api_token
  ], coder: JSON

  validates_presence_of :club
  validates_presence_of :transport
  validates_uniqueness_of :transport, scope: :club
  validates :client_id, :client_secret, :access_token, presence: true, if: -> { facebook? }
  validates :api_key, presence: true, if: -> { mailchimp? }
  validates :tracking_id, presence: true, if: -> { google_analytics? }
  validates :container_id, presence: true, if: -> { google_tag_manager? }
  validates :url, presence: true, format: /(^$)|(^(http|https):\/\/([\w]+:\w+@)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix, if: -> { store_spree? }
  
  enum transport: {
    facebook:           0,
    mailchimp:          1,
    # twitter:          2,
    # adwords:          3,
    google_analytics:   4,
    google_tag_manager: 5,
    store_spree:        6
  }

  def self.datatable_columns
    ['id', 'transport']
  end

  def test_connection!
    raise TransportDoesntSupportAction.new unless store_spree?
    test_store_connection
  end

  def credentials_correctly_configured?
    settings and settings['url'] and settings['api_token'].present? if store_spree?
  end

  private
    scope :by_transport, -> (transport) {
      unless transport.kind_of? Integer
        transport = Campaign.transports[transport.to_s]
      end
      where(transport: transport)
    }
end
