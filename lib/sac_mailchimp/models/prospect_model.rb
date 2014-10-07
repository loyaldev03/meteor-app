module SacMailchimp
	class ProspectModel < Struct.new(:prospect)

    def save!(club)
      return unless self.prospect.email
      setup_club(club)
      subscriber = SacMailchimp::ProspectModel.find_by_email self.prospect.email, mailchimp_list_id
      res = if subscriber["status"]=='error'
        subscriber
      elsif subscriber["success_count"] == 0
        begin 
          options = {:double_optin => false}
          client.lists.subscribe( subscriber({:email => self.prospect.email}, options) )
        rescue Exception => e
          Auditory.audit(nil, self.prospect, e, Prospect.find_by_email_and_club_id(self.prospect.email,self.prospect.club_id), Settings.operation_types.mailchimp_timeout_create) if e.to_s.include?("Timeout")
          raise e
        end       
      elsif SacMailchimp::ProspectModel.email_belongs_to_prospect_and_no_user?(subscriber["data"].first["email"], club_id)
        begin
          options = { :update_existing => true, :double_optin => false }
          client.lists.subscribe( subscriber({:email => self.prospect.email}, options) )
        rescue Exception => e
          Auditory.audit(nil, self.prospect, e, Prospect.find_by_email_and_club_id(self.prospect.email,self.prospect.club_id), Settings.operation_types.mailchimp_timeout_update) if e.to_s.include?("Timeout")
          raise e
        end
      else
        res = { "error" => "Email already saved as member." }
      end
      update_prospect(res)
    end

    def self.email_belongs_to_prospect_and_no_user?(email, club_id)
      not Prospect.find_by_email_and_club_id(email, club_id).nil? and User.find_by_email_and_club_id(email, club_id).nil?
    end

    def update_prospect(res)
      data = {}
      unless res.nil?
        data = if res["error"]
          { marketing_client_sync_result: res["error"] }
        else
          { marketing_client_sync_result: 'Success' }
        end
      end
      data = data.merge(need_sync_to_marketing_client: false)
      ::Prospect.where(uuid: self.prospect.uuid).limit(1).update_all(data)
      self.prospect.reload rescue self.prospect
    end

    def subscriber(mailchimp_identification ,options={})
    	attributes = {"STATUS" => 'prospect'}
    	fieldmap.each do |api_field, our_field| 
        attributes.merge!(SacMailchimp.format_attribute(self.prospect, api_field, our_field))
      end
      if Rails.env.production? and self.prospect.preferences and preferences_fieldmap
        preferences_fieldmap.each do |api_field, our_field|
          attributes.merge!({ api_field => self.prospect.preferences[our_field].to_s })
        end
      elsif Rails.env.prototype? and self.prospect.preferences
        attributes.merge!({ "PREF1" => self.prospect.preferences["example_color"].to_s })
        attributes.merge!({ "PREF2" => self.prospect.preferences["example_team"].to_s })
      end
			{ id: mailchimp_list_id , :email => mailchimp_identification, :merge_vars => attributes }.merge!(options)
    end

		def fieldmap
		  { 
        'EMAIL' => 'email',
		    'FNAME' => 'first_name',
		    'LNAME' => 'last_name',
		    'ADDRESS' => 'address',
		    'CITY' => 'city',
		    'STATE' => 'state',
		    'ZIP' => 'zip',
		    'BIRTHDATE' => 'birth_date',
		    'GENDER' => 'gender',
		    'PHONE' => 'full_phone_number',
        'TOMID' => 'terms_of_membership_id',
        'JOINDATE' => 'created_at',
        'MKTCODE' => 'marketing_code',
        'MCHANNEL' => 'mega_channel',
        'FCODE' => 'fulfillment_code',
        'CMEDIUM' => 'campaign_medium',
        'PRODUCTSKU' => 'product_sku',
        'LANDINGURL' => 'landing_url',
      }
    end

		def preferences_fieldmap
      case self.prospect.club_id
        when 1
          {
            "PREF1" => "driver_1",
            "PREF2" => "driver_2",
            "PREF3" => "car",
            "PREF4" => "track"
          }
        when 5
          {
            "PREF1" => "rv_type",
            "PREF2" => "rv_make",
            "PREF3" => "rv_model",
            "PREF4" => "rv_year"
            # "pref_field_5" => "rv_miles",
            # "pref_field_6" => "fav_dest",
            # "pref_field_7" => "fav_use"
          }
        when 8
          {
            "PREF1" => "fav_team"
          }
        when 9
          {
            "PREF1" => "car_year",
            "PREF2" => "car_made"
          }
      end
    end

    def client
      Gibbon::API.new
    end

    def self.find_all_by_email!(email, list)
      # Find by email . I didnt have luck looking for a subscriber by email and List.
      res = Gibbon::API.lists.member_info({ id: list, emails: [{email: email}] })
    rescue Exception => e
      Auditory.audit(nil, nil, e, Prospect.find_by_email_and_club_id(email,club_id), Settings.operation_types.et_timeout_find) if e.to_s.include?("Timeout")
      raise e
    end
    
    def setup_club(club)
      @club = club.nil? ? self.prospect.club : club
    end
    
    def club_id
      @club.id.to_s
    end

    def self.find_by_email(email, list)
      find_all_by_email!(email, list)
    end
 
    def mailchimp_list_id
    	@list_id ||= self.prospect.club.marketing_tool_attributes["mailchimp_list_id"]
    end
	end
end