class TransportSetting < ActiveRecord::Base
  belongs_to :club

  enum transport: {
    facebook:   0,
    mailchimp:  1,
    twitter:    2,
    adwords:    3
  }

  serialize :settings, JSON
end