module SacExactTarget
  class MemberModel < Struct.new(:member)

    def save!
      client, options = ExactTargetSDK::Client.new, {}
      update_member(new_record? ? create! : update!)
    end

    def new_record?
      # Find by subscriber key . I didnt have luck looking for a subscriber by email and List.
      res = ExactTargetSDK::Subscriber.find [ ["SubscriberKey", ExactTargetSDK::SimpleOperator::EQUALS, self.member.id] ]
      @subscriber = res.Results.collect do |result|
        result.attributes.select {|d| d == { :name => "Club", :value => club_id } }.empty? ? nil : result
      end.flatten.first
      @subscriber.nil?
    end

  private

    def create!
      client, options = ExactTargetSDK::Client.new, {}
      options[:subscribe_to_list] = true
      # Remove email from prospect list
      SacExactTarget::ProspectModel.destroy_by_email self.member.email, club_id
      # Add customer under member list
      client.Create(subscriber(self.member.id, options))
    end

    def update!
      client, options = ExactTargetSDK::Client.new, {}
      options[:subscribe_to_list] = false
      client.Update(subscriber(self.member.id, options))
    end

    def update_member(res)
      data = if res.OverallStatus != "OK"
        Auditory.report_issue("SacExactTarget:Member:save", res.Results.first.status_message, { :result => res.inspect })
        { 
          exact_target_last_synced_at: nil,
          exact_target_synced_status: 'error',
          exact_target_last_sync_error: res.Results.first.status_message,
          exact_target_last_sync_error_at: Time.zone.now
        }
      else
        {
          exact_target_last_synced_at: Time.zone.now,
          exact_target_synced_status: 'synced',
          exact_target_last_sync_error: nil,
          exact_target_last_sync_error_at: nil
        }
      end
      ::Member.where(id: self.member.id).limit(1).update_all(data)
      self.member.reload rescue self.member
    end

    def subscriber(subscriber_key, options ={})
      # TODO: marketing_tool_attributes['et_members_list'] must be an extended method from club 
      attributes, list = [], [ ExactTargetSDK::List.new(ID: self.member.club.marketing_tool_attributes['et_members_list'], Status: 'Active', Action: 'create') ]
      fieldmap.each do |api_field, our_field| 
        attributes << add_attribute(self.member, api_field, our_field)
      end
      membership = self.member.current_membership
      membership_fieldmap.each do |api_field, our_field| 
        attributes << add_attribute(membership, api_field, our_field)
      end
      enrollment_info = membership.enrollment_info
      enrollment_fieldmap.each do |api_field, our_field| 
        attributes << add_attribute(enrollment_info, api_field, our_field)
      end  
      attributes << ExactTargetSDK::Attributes.new(Name: 'Club', Value: club_id)
      id = ExactTargetSDK::SubscriberClient.new(ID: business_unit_id)
      ExactTargetSDK::Subscriber.new({
        'SubscriberKey' => subscriber_key, 
        'EmailAddress' => self.member.email, 'Client' => id, 'ObjectID' => true, 
        'Attributes' => attributes.compact }.merge(options[:subscribe_to_list] ? { 'Lists' => list } : {} ))        
    end

    def add_attribute(object, api_field, our_field)
      value = object.send(our_field)
      unless value.blank?
        if value.class == ActiveSupport::TimeWithZone
          ExactTargetSDK::Attributes.new(Name: api_field, Value: I18n.l(value)) 
        else
          ExactTargetSDK::Attributes.new(Name: api_field, Value: value) 
        end
      end
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
        'Phone' => 'full_phone_number'
      }
    end

    def membership_fieldmap
      {
        'Membership_status' => 'status',
        'Terms_of_membership' => 'terms_of_membership_id',
        'Join_date' => 'join_date',
        'Cancel_date' => 'cancel_date',
        'Quota' => 'quota'
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

    def aditional_fieldmap
      { 
        'Installment_amount' => '',
        'Refunded_amount' => ''
      }
    end

    def club_id
      Rails.env == 'production' ? self.member.club_id : '9999'
    end
    
    def business_unit_id
      Rails.env == 'production' ? self.club.marketing_tool_attributes['et_business_unit'] : Settings.exact_target.business_unit_for_test
    end
  end
end

