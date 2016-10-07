class Campaign < ActiveRecord::Base
  belongs_to :club
  belongs_to :transport_setting
  has_many :campaign_days
  belongs_to :terms_of_membership

  before_validation :set_utm_medium
  before_validation :set_campaign_code
  before_save :set_utm_content
  before_create :set_landing_url
  after_update :fetch_campaign_days_data

  validates :name, :landing_name, :initial_date, :campaign_type, :transport, 
            :utm_medium, :utm_content, :audience, :campaign_code,
            presence: true
  validates :terms_of_membership, :enrollment_price, presence: true, if: -> { enrollment_related? }

  validates_date :finish_date, after: :initial_date, if: -> { finish_date.present? }
  validates_date :initial_date, after: lambda { Time.zone.now }, if: -> { (initial_date_changed? || finish_date_changed?) && !can_set_dates_in_the_past? }

  TRANSPORTS_FOR_MANUAL_UPDATE = ['twitter', 'adwords']
  NO_ENROLLMENT_CAMPAIGN_TYPE = ['store_promotion', 'newsletter']

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
  
  scope :active, -> (date = nil) {
    where("initial_date <= :current_date AND (finish_date >= :current_date OR finish_date IS NULL)", current_date: (date||Date.current).to_date)
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

  def enrollment_related?
    NO_ENROLLMENT_CAMPAIGN_TYPE.exclude? campaign_type
  end

  def missing_days(date: Date.current)
    if mailchimp?
      campaign_day = CampaignDay.where(campaign: self, date: initial_date).first
      if campaign_day 
        campaign_day.is_missing? ? [campaign_day] : []
      else
        [CampaignDay.create(campaign: self, date: initial_date).tap(&:readonly!)]
      end
    else
      all_days = past_period(date).to_a
      present_days = campaign_days.where(campaign_id: self).not_missing.pluck(:date)
      (all_days - present_days).map { |missing_date|
        CampaignDay.where(campaign: self, date: missing_date).first_or_create.tap(&:readonly!)
      }
    end
  end

  def set_campaign_code
    self.campaign_code = Array.new(16){ rand(36).to_s(36) }.join unless campaign_code
  end

  def can_edit_transport_id?
    campaign_days.invalid_campaign.first.present?
  end

  def can_set_dates_in_the_past?
    # https://www.pivotaltracker.com/story/show/118308773/comments/148110267
    !campaign_days.first.present?
  end

  def set_landing_url
    url = (enrollment_related? ? club.member_landing_url : club.store_url).to_s + '/' + landing_name.to_s
    parameters = [
      "utm_campaign=#{campaign_type}",
      "utm_source=#{transport}",
      "utm_medium=#{utm_medium}",
      "utm_content=#{utm_content}",
      "audience=#{audience}",
      "campaign_id=#{campaign_code}"
      ]
    self.landing_url = url + '?' + parameters.join('&')
  end

  private
    def past_period(date = Date.current)
      if mailchimp?
        [ initial_date ]
      else
        initial_date .. ((finish_date.nil? || finish_date > date) ? date : finish_date)
      end
    end

    def set_utm_medium
      self.utm_medium = case transport
        when 'facebook', 'twitter'
          :display
        when 'mailchimp'
          :email
        when 'adwords'
          :search
      end
    end

    def set_utm_content
      unless (self.utm_content.start_with?('email_') || self.utm_content.start_with?('banner_'))
        self.utm_content = (mailchimp? ? 'email' : 'banner') + '_' + utm_content
      end
    end

    def fetch_campaign_days_data
      if transport_campaign_id_changed?
        Campaigns::DataFetcherJob.perform_later(club_id: club_id, transport: transport, campaign_id: self.id)
      end
    end
end