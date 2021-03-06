module SacMailchimp
	class ProspectModel < Struct.new(:prospect)

    def save!(club)
      setup_club(club)
      res = if self.prospect.email and not ["mailinator.com", "test.com", "noemail.com"].include? self.prospect.email.split("@")[1]
        subscriber = client.lists(mailchimp_list_id).members(email).retrieve rescue nil
        if subscriber.blank?
          client.lists(mailchimp_list_id).members.create(body: { email_address: self.prospect.email.downcase, status: 'subscribed', merge_fields: subscriber_data })
        elsif SacMailchimp::ProspectModel.email_belongs_to_prospect_and_no_user?(self.prospect.email, club_id)
          client.lists(mailchimp_list_id).members(email).update(body: { status: 'subscribed', merge_fields: subscriber_data })
        else
          Gibbon::MailChimpError.new('Synchronization canceled.', { detail: "Email already saved as member." })
        end
      else 
        Gibbon::MailChimpError.new('Synchronization canceled.', { detail: "Email address looks fake or invalid. Synchronization was canceled." })
      end
      update_prospect(res)
    rescue Exception => e
      update_prospect(Gibbon::MailChimpError.new("unexpected error", { detail: e.to_s }))
      raise e
    end

    def self.email_belongs_to_prospect_and_no_user?(subscriber_email, club_id)
      not Prospect.find_by_email_and_club_id(subscriber_email, club_id).nil? and User.find_by_email_and_club_id(subscriber_email, club_id).nil?
    end

    def update_prospect(res)
      data = {}
      unless res.nil?
        data = if res.instance_of? Gibbon::MailChimpError
          { marketing_client_sync_result: res.detail.truncate(255) }
        else
          { marketing_client_sync_result: 'Success' }
        end
      end
      data = data.merge(need_sync_to_marketing_client: false)
      ::Prospect.where(uuid: self.prospect.uuid).limit(1).update_all(data)
      self.prospect.reload rescue self.prospect
    end

    def subscriber_data
    	attributes = {"STATUS" => 'prospect'}
    	fieldmap.each do |api_field, our_field|
        attributes.merge!(SacMailchimp.format_attribute(self.prospect, api_field, our_field))
      end
      if self.prospect.preferences and preferences_fieldmap
        preferences_fieldmap.each do |api_field, our_field|
          attributes.merge!({ api_field => self.prospect.preferences[our_field].to_s })
        end
      end
      attributes
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
        'AUDIENCE' => 'audience',
        'CTYPE' => 'utm_campaign',
        'CAMPAIGNID' => 'campaign_code',
        'MEDIUM' => 'utm_medium',
        'PRODUCTSKU' => 'product_sku',
        'LANDINGURL' => 'landing_url'
      }
    end

    def preferences_fieldmap
      if Settings['club_params'] && Settings['club_params'][@club.id] && Settings['club_params'][@club.id]['preferences']
        Settings['club_params']['preferences']
      end
    end

    def client
      Gibbon::Request.new
    end

    def setup_club(club)
      @club = club.nil? ? self.prospect.club : club
    end
    
    def club_id
      @club.id.to_s
    end

    def email
      Digest::MD5.hexdigest(self.prospect.email.downcase)
    end

    def mailchimp_list_id
    	@list_id ||= self.prospect.club.marketing_tool_attributes["mailchimp_list_id"]
    end
	end
end
