class Campaign < ActiveRecord::Base
  belongs_to :club
  belongs_to :transport_setting
  has_many :campaign_days
  belongs_to :terms_of_membership

  before_validation :set_campaign_medium
  before_save :set_campaign_medium_version
  before_save :set_fulfillment_code
  
  validates :name, :enrollment_price, :initial_date, :campaign_type, :transport, 
            :campaign_medium, :campaign_medium_version, :marketing_code, :fulfillment_code,
            :terms_of_membership_id, presence: true

  validate :check_dates_range

  enum campaign_type: {
     sloop:           0,
     ptx:             1,
     sweeptake:       2,
     store_promotion: 3,
     newsletter:      4,
     daily_candy:     5,
     freemium:        6
   }

  enum transport: {
    facebook:   0,
    mailchimp:  1,
    twitter:    2,
    adwords:    3
  }

  scope :by_transport, -> (transport) {
    unless transport.kind_of? Integer
      transport = Campaign.transports[transport.to_s]
    end
    where(transport: transport)
  }
 
  def self.datatable_columns
    [ 'id', 'name', 'campaign_type', 'transport', 'initial_date', 'finish_date' ]
  end

  private
    def set_fulfillment_code
      self.fulfillment_code = Array.new(16){ rand(36).to_s(36) }.join if self.fulfillment_code == 'New automatic code'
    end

    def set_campaign_medium
      self.campaign_medium = case transport
        when 'facebook', 'twitter'
          :display
        when 'mailchimp'
          :email
        when 'adwords'
          :search
      end
    end

    def set_campaign_medium_version
      self.campaign_medium_version = (mailchimp? ? 'email' : 'banner') + '_' + campaign_medium_version
    end

    def check_dates_range
      if finish_date and initial_date
        if finish_date.to_date < initial_date.to_date
          errors.add(:finish_date, "Must be greater or equal than initial date.")
        end
      end
    end
end