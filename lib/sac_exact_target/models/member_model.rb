module SacExactTarget
  class MemberModel < Struct.new(:user)

    def save!
      update_member(new_record? ? create! : update!)
    end

    def new_record?
      # Find by subscriber key. We cant get the list of Lists to which this subscriber is subscribe it on. 
      res = ExactTargetSDK::Subscriber.find [ ["SubscriberKey", ExactTargetSDK::SimpleOperator::EQUALS, subscriber_key ] ]
      @subscriber = res.Results.first
      @subscriber.nil?
    rescue Exception  => e
      Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.et_timeout_retrieve) if e.to_s.include?("Timeout")
      raise e
    end

    def unsubscribe!
      change_status! 'Unsubscribed'
    end

    def subscribe!
      change_status! 'Active'
    end

    def send_email(customer_key)
      trigger_definition = ExactTargetSDK::TriggeredSendDefinition.new('CustomerKey' => customer_key)
      s = ExactTargetSDK::Subscriber.new({ 'SubscriberKey' => subscriber_key, 'EmailAddress' => self.user.email })
      trigger_to_send = ExactTargetSDK::TriggeredSend.new(
        'TriggeredSendDefinition' => trigger_definition, 
        'Client' => client_id,
        'Subscribers' => [s] )
      client.Create(trigger_to_send)
    rescue Exception => e
      Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.et_timeout_trigger_create) if e.to_s.include?("Timeout")
      raise e
    end

  private
    def client
      ExactTargetSDK::Client.new
    end

    def change_status!(status)
      attributes = [ 
       ExactTargetSDK::Attributes.new(Name: 'Club', Value: club_id), 
       ExactTargetSDK::Attributes.new(Name: 'Status', Value: status) 
      ]
      s = ExactTargetSDK::Subscriber.new({
        'SubscriberKey' => subscriber_key, 'Status' => status,
        'EmailAddress' => self.user.email, 'Client' => client_id, 'ObjectID' => true,
        'Attributes' => attributes
      })
      client.Update(s)
    rescue Exception => e
      Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.et_timeout_update) if e.to_s.include?("Timeout")
      raise e
    end

    def create!
      options = { :subscribe_to_list => true }
      # Remove email from prospect list
      SacExactTarget::ProspectModel.destroy_by_email! self.user.email, club_id
      # Add customer under member list
      begin
        client.Create(subscriber(subscriber_key, options))
      rescue Exception => e
        Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.et_timeout_create) if e.to_s.include?("Timeout")
        raise e
      end
    end

    def update!
      # @subscriber does not have the list of Lists. So I have to check if it has a Club. 
      # We assume that everyone in a Club has a list
      options = { :subscribe_to_list => !@subscriber.attributes.select { |s| s[:name] == 'Club' and s[:value].nil? }.empty? }
      client.Update(subscriber(subscriber_key, options))
    rescue Exception => e
      Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.et_timeout_update) if e.to_s.include?("Timeout")
      raise e 
    end

    def update_member(res)
      data = if res.nil?
        { 
          marketing_client_synced_status: 'error',
          marketing_client_last_sync_error: "Time out error.",
          marketing_client_last_sync_error_at: Time.zone.now
        }        
      elsif res.OverallStatus != "OK"
        SacExactTarget::report_error("SacExactTarget:Member:save", res)
        { 
          marketing_client_synced_status: 'error',
          marketing_client_last_sync_error: res.Results.first.status_message,
          marketing_client_last_sync_error_at: Time.zone.now
        }
      else
        {
          marketing_client_last_synced_at: Time.zone.now,
          marketing_client_synced_status: 'synced',
          marketing_client_last_sync_error: nil,
          marketing_client_last_sync_error_at: nil
        }
      end
      data = data.merge(need_sync_to_marketing_client: false)
      ::User.where(id: self.user.id).limit(1).update_all(data)
      self.user.reload rescue self.user
    end

    def subscriber(subscriber_key, options ={})
      # TODO: marketing_tool_attributes['et_members_list'] must be an extended method from club 
      attributes, list = [], [ ExactTargetSDK::List.new(ID: self.user.club.marketing_tool_attributes['et_members_list'], Status: 'Active', Action: 'create') ]
      fieldmap.each do |api_field, our_field| 
        attributes << SacExactTarget.format_attribute(self.user, api_field, our_field)
      end
      membership = self.member.current_membership
      membership_fieldmap.each do |api_field, our_field| 
        attributes << SacExactTarget.format_attribute(membership, api_field, our_field)
      end
      terms_of_membership = membership.terms_of_membership
      terms_of_membership_fieldmap.each do |api_field, our_field| 
        attributes << SacExactTarget.format_attribute(terms_of_membership, api_field, our_field)
      end
      enrollment_info = membership.enrollment_info
      enrollment_fieldmap.each do |api_field, our_field| 
        attributes << SacExactTarget.format_attribute(enrollment_info, api_field, our_field)
      end  
      if Rails.env.production? and self.user.preferences and preferences_fieldmap
        user_preferences = self.user.user_preferences
        preferences_fieldmap.each do |api_field, our_field|
          attributes << ExactTargetSDK::Attributes.new(Name: api_field, Value: self.user.preferences[our_field].to_s)
        end
      elsif Rails.env.prototype? and self.user.preferences
        attributes << ExactTargetSDK::Attributes.new(Name: "pref_field_1", Value: self.user.preferences["example_color"].to_s)
        attributes << ExactTargetSDK::Attributes.new(Name: "pref_field_2", Value: self.user.preferences["example_team"].to_s)
      end
      attributes << ExactTargetSDK::Attributes.new(Name: 'Club', Value: club_id)
      ExactTargetSDK::Subscriber.new({
        'SubscriberKey' => subscriber_key, 
        'EmailAddress' => self.user.email, 'Client' => client_id, 'ObjectID' => true, 
        'Attributes' => attributes.compact }.
        merge(options[:subscribe_to_list] ? { 'Lists' => list } : {} )
      )        
    end

    def fieldmap
      { 
        'First_name' => 'first_name',
        'Last_name' => 'last_name',
        'Address_one' => 'address',
        'City' => 'city',
        'State' => 'state',
        'Zip' => 'zip',
        'Country' => 'country',
        'Birth_date' => 'birth_date',
        'Member_since_date' => 'member_since_date',
        'Wrong_address' => 'wrong_address',
        'Next_bill_date' => 'next_retry_bill_date',
        'External_id' => 'external_id',
        'Club_cash_amount' => 'club_cash_amount',
        'Gender' => 'gender',
        'Wrong_Phone' => 'wrong_phone_number',
        'Phone' => 'full_phone_number',
        'Refunded_amount' => 'last_refunded_amount'
      }
    end

    def membership_fieldmap
      {
        'Membership_status' => 'status',
        'Terms_of_membership' => 'terms_of_membership_id',
        'Join_date' => 'join_date',
        'Cancel_date' => 'cancel_date',
      }
    end

    def enrollment_fieldmap
      { 
        'Marketing_code' => 'marketing_code',
        'Mega_channel' => 'mega_channel',
        'Fulfillment_code' => 'fulfillment_code',
        'Campaign_medium' => 'campaign_medium',
        'Product_sku' => 'product_sku',
        'Landing_URL' => 'landing_url',
        'Enrollment_amount' => 'enrollment_amount'
      }
    end

    def terms_of_membership_fieldmap
      { 
        'Installment_amount' => 'installment_amount'
      }
    end

    def preferences_fieldmap
      case self.user.club_id
        when 1
          {
            "pref_field_1" => "driver_1",
            "pref_field_2" => "driver_2",
            "pref_field_3" => "car",
            "pref_field_4" => "track"
          }
        when 5
          {
            "pref_field_1" => "rv_type",
            "pref_field_2" => "rv_make",
            "pref_field_3" => "rv_model",
            "pref_field_4" => "rv_year",
            "pref_field_5" => "rv_miles",
            "pref_field_6" => "fav_dest",
            "pref_field_7" => "fav_use"
          }
        when 8
          {
            "pref_field_1" => "fav_team"
          }
        when 9
          {
            "pref_field_1" => "car_year",
            "pref_field_2" => "car_made"
          }
      end
    end

    def subscriber_key
      Rails.env.production? ? self.user.id : "#{Rails.env}-#{self.user.id.to_s}"
    end

    def club_id
      Rails.env.production? ? self.user.club_id.to_s : '9999'
    end

    def client_id
      ExactTargetSDK::SubscriberClient.new(ID: business_unit_id)
    end
    
    def business_unit_id
      Rails.env.production? ? self.user.club.marketing_tool_attributes['et_business_unit'] : Settings.exact_target.business_unit_for_test
    end
  end
end

