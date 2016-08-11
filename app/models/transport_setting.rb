class TransportSetting < ActiveRecord::Base
  belongs_to :club

  enum transport: {
    facebook:   0,
    mailchimp:  1,
    twitter:    2,
    adwords:    3
  }

  serialize :settings, JSON
  scope :by_transport, -> (transport) {
    unless transport.kind_of? Integer
      transport = Campaign.transports[transport.to_s]
    end
    where(transport: transport)
  }
end