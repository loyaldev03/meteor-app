class TransportSetting < ActiveRecord::Base
  belongs_to :club

  store :settings, accessors: [ 
    :client_id, :client_secret, :access_token,
    :api_key
  ], coder: JSON

  validates_presence_of :club
  validates_presence_of :transport
  validates_uniqueness_of :transport, scope: :club
  validates :client_id, :client_secret, :access_token, presence: true, if: -> { facebook? }
  validates :api_key, presence: true, if: -> { mailchimp? }

  enum transport: {
    facebook:   0,
    mailchimp:  1,
    # twitter:    2,
    # adwords:    3
  }

  def self.datatable_columns
    ['id', 'transport']
  end

  private
    scope :by_transport, -> (transport) {
      unless transport.kind_of? Integer
        transport = Campaign.transports[transport.to_s]
      end
      where(transport: transport)
    }
end
