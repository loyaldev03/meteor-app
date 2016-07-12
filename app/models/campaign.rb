class Campaign < ActiveRecord::Base
  belongs_to :campaign

  validates :name, :enrollment_price, :initial_date, :finish_date, :campaign_type, :transport, 
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

  def set_data(params)
    self.name                     = params[:name]
    self.transport                = params[:transport]
    self.campaign_type            = params[:campaign_type]
    self.initial_date             = params[:initial_date]
    self.finish_date              = params[:finish_date]
    self.campaign_medium_version  = 
    set_campaign_medium
  end

  private
    def check_dates_range
      if finish_date and initial_date
        if finish_date.to_date < initial_date.to_date
          errors.add(:finish_date, "Can't be set before the initial date.")
        end
      end
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
end
