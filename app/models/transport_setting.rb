class TransportSetting < ActiveRecord::Base
  belongs_to :club

  before_update :custom_update

  enum transport: {
    facebook:   0,
    mailchimp:  1,
    twitter:    2,
    adwords:    3
  }

  serialize :settings, JSON

  private
    def custom_update

    end
end