module SacMailchimp
	class MemberModel < Struct.new(:user)

    def save!
      update_member(new_record? ? create! : update!)
    end

    def new_record?
      # Find by subscriber key. We cant get the list of Lists to which this subscriber is subscribe it on. 
      mailchimp_identification = self.user.marketing_client_id.nil? ? {email: self.user.email} : {euid: self.user.marketing_client_id}
      res = Gibbon::API.lists.member_info({ id: mailchimp_list_id, emails: [mailchimp_identification] })
      @subscriber = res
      @subscriber["success_count"] == 0
    rescue Gibbon::MailChimpError => e
      update_member e
      raise e.inspect
    rescue Exception  => e
      Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.mailchimp_timeout_retrieve) if e.to_s.include?("Timeout")
      raise e
    end

    def unsubscribe!
    	begin
      	client.lists.unsubscribe({:id => mailchimp_list_id, :email => { :email => self.user.email }})
      rescue Gibbon::MailChimpError => e
        update_member e
        raise e.inspect
    	rescue Exception => e
	      Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.mailchimp_timeout_update) if e.to_s.include?("Timeout")
	      raise e 
    	end
    end

    def subscribe!
      self.save!
    end

    def create!
			options = {:double_optin => false}
      begin
      	client.lists.subscribe( subscriber({:email => self.user.email}, options) )
      rescue Gibbon::MailChimpError => e
        update_member e
        raise e.inspect
      rescue Exception => e
        Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.mailchimp_timeout_create) if e.to_s.include?("Timeout")
        raise e
      end
    end

    def update!
    	options = { :update_existing => true, :double_optin => false }
    	begin
        # We check if the subscriber is a prospect or not. In case it is a prospect we make reference 
        # to the leid we do not have saved. In case it is not prospect we use marketing_client we have.
        # TODO: if we have a marketing_client_id in prospect too we would be avoiding this step.
        mailchimp_identification = self.user.marketing_client_id.nil? ? @subscriber["data"].first["leid"] : self.user.marketing_client_id
      	client.lists.subscribe( subscriber({:euid => mailchimp_identification}, options) )
      rescue Gibbon::MailChimpError => e
        update_member e
        raise e.inspect
    	rescue Exception => e
	      Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.mailchimp_timeout_update) if e.to_s.include?("Timeout")
	      raise e
    	end
    end

		def update_member(res)
      data = if res.nil?
        { 
          marketing_client_synced_status: 'error',
          marketing_client_last_sync_error: "Time out error.",
          marketing_client_last_sync_error_at: Time.zone.now
        }        
      elsif res.instance_of? Gibbon::MailChimpError 
        { 
          marketing_client_synced_status: 'error',
          marketing_client_last_sync_error: "Code: #{res.code} Message: #{res.message}.",
          marketing_client_last_sync_error_at: Time.zone.now
        }
      else
        {
          marketing_client_last_synced_at: Time.zone.now,
          marketing_client_synced_status: 'synced',
          marketing_client_last_sync_error: nil,
          marketing_client_last_sync_error_at: nil,
          marketing_client_id: res["euid"]
        }
      end
      data = data.merge(need_sync_to_marketing_client: false)
      ::User.where(id: self.user.id).limit(1).update_all(data)
      self.user.reload rescue self.user
    end

    def subscriber(mailchimp_identification ,options={})
    	attributes = {}
    	fieldmap.each do |api_field, our_field| 
        attributes.merge!(SacMailchimp.format_attribute(self.user, api_field, our_field))
      end
      membership = self.user.current_membership
      membership_fieldmap.each do |api_field, our_field| 
        attributes.merge!(SacMailchimp.format_attribute(membership, api_field, our_field))
      end
      terms_of_membership = membership.terms_of_membership
      terms_of_membership_fieldmap.each do |api_field, our_field| 
        attributes.merge!(SacMailchimp.format_attribute(terms_of_membership, api_field, our_field))
      end
      enrollment_info = membership.enrollment_info
      enrollment_fieldmap.each do |api_field, our_field| 
        attributes.merge!(SacMailchimp.format_attribute(enrollment_info, api_field, our_field))
      end
      if Rails.env.production? and self.user.preferences and preferences_fieldmap
        member_preferences = self.user.user_preferences
        preferences_fieldmap.each do |api_field, our_field|
          attributes.merge!({ api_field => self.user.preferences[our_field].to_s })
        end
      elsif Rails.env.prototype? and self.user.preferences
        attributes.merge!({ "PREF1" => self.user.preferences["example_color"].to_s })
        attributes.merge!({ "PREF2" => self.user.preferences["example_team"].to_s })
      end

			{ id: mailchimp_list_id, :email => mailchimp_identification, :merge_vars => attributes }.merge!(options)
    end

    #If any of these variables are changed, please check Mandrill's variable too.
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
		    'MSINCEDATE' => 'member_since_date',
		    'BILLDATE' => 'next_retry_bill_date',
		    'EXTERNALID' => 'external_id',
		    'GENDER' => 'gender',
		    'PHONE' => 'full_phone_number'
		  }
		end

    def membership_fieldmap
      {
        'STATUS' => 'status',
        'TOMID' => 'terms_of_membership_id',
        'JOINDATE' => 'join_date',
        'CANCELDATE' => 'cancel_date',
      }
    end

    def enrollment_fieldmap
      { 
        'MKTCODE' => 'marketing_code',
        'MCHANNEL' => 'mega_channel',
        'FCODE' => 'fulfillment_code',
        'CMEDIUM' => 'campaign_medium',
        'PRODUCTSKU' => 'product_sku',
        'LANDINGURL' => 'landing_url',
        'EAMOUNT' => 'enrollment_amount'
      }
    end

    def terms_of_membership_fieldmap
      { 
        'IAMOUNT' => 'installment_amount'
      }
    end

		def preferences_fieldmap
      case self.user.club_id
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

    def mailchimp_list_id
    	@list_id ||= self.user.club.marketing_tool_attributes["mailchimp_list_id"]
    end
	end
end