class Prospect < ActiveRecord::Base
  include Extensions::UUID

  has_many :enrollment_infos
  belongs_to :terms_of_membership

  serialize :preferences, JSON
  serialize :referral_parameters, JSON

  after_create :after_create_sync_to_remote_domain
  def after_create_sync_to_remote_domain
    sync_to_remote_domain unless pardot_prospect.nil?
  end

  attr_accessible :first_name, :last_name, :address, :city, :state, :zip, :email,:phone_country_code, 
   				  :phone_area_code ,:phone_local_number, :birth_date, :preferences, :gender, 
   				  :ip_address, :referral_host, :referral_parameters, :cookie_value,:marketing_code, 
            :product_sku, :user_id, :landing_url, :mega_channel, :user_agent, :joint,
            :campaign_medium, :campaign_description, :campaign_medium_version , :terms_of_membership_id, 
            :country, :type_of_phone_number, :fulfillment_code, :referral_path, :cookie_set, :product_description


  def pardot_prospect
    @pardot_prospect ||= if !self.club.pardot_sync?
      nil
    else
      Pardot::Prospect.new self
    end
  end

  def full_phone_number
    "(#{self.phone_country_code}) #{self.phone_area_code} - #{self.phone_local_number}"
  end


  def sync_to_remote_domain
    time_elapsed = Benchmark.ms do
      pardot_prospect.save! unless pardot_prospect.nil?
    end
    logger.info "Pardot::sync took #{time_elapsed}ms"
  rescue Exception => e
    Airbrake.notify(:error_class => "Prospect:sync", :error_message => e, :parameters => { :prospect => self.inspect })
  end
  handle_asynchronously :sync_to_remote_domain


end
