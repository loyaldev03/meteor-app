module SacExactTarget
  class MemberModel < Struct.new(:member)

    def save!
      client, options = ExactTargetSDK::Client.new, {}
      update_member(new_record? ? self.create! : self.update!)
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
      SacExactTarget::ProspectModel.destroy_by_email self.member.email
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
      attributes, list = [], [ ExactTargetSDK::List.new(ID: self.member.club.marketing_tool_attributes['et_member_list'], Status: 'Active', Action: 'create') ]
      fieldmap.each do |api_field, our_field| 
        attributes << ExactTargetSDK::Attributes.new(Name: api_field, Value: self.member.send(our_field)) unless self.member.send(our_field).blank?
      end
      membership = self.member.current_membership
      membership_fieldmap.each do |api_field, our_field| 
        attributes << ExactTargetSDK::Attributes.new(Name: api_field, Value: membership.send(our_field)) unless membership.send(our_field).blank?
      end
      enrollment_info = membership.enrollment_info
      enrollment_fieldmap.each do |api_field, our_field| 
        attributes << ExactTargetSDK::Attributes.new(Name: api_field, Value: enrollment_info.send(our_field)) unless enrollment_info.send(our_field).blank?
      end  
      attributes << ExactTargetSDK::Attributes.new(Name: 'Club', Value: club_id)
      id = ExactTargetSDK::SubscriberClient.new(ID: business_unit_id)
      ExactTargetSDK::Subscriber.new({
        'SubscriberKey' => subscriber_key, 
        'EmailAddress' => self.member.email, 'Client' => id, 'ObjectID' => true, 
        'Attributes' => attributes.compact }.merge(options[:subscribe_to_list] ? { 'Lists' => list } : {} ))        
    end

    def fieldmap(options)
      [ 
        'First_name' => 'first_name',
        'Last_name' => 'last_name',
        'Address_one' => 'address',
        'City' => 'city',
        'State' => 'state',
        'Zip' => 'zip',
        'Country' => 'country',
        'Birth_date' => 'birth_date',
        'Club' => 'club_id', 
        'Member_since_date' => 'member_since_date',
        'Wrong_address' => 'wrong_address',
        'Next_bill_date' => 'next_retry_bill_date',
        'External_id' => 'external_id',
        'Club_cash_amount' => 'club_cash_amount',
        'Gender' => 'gender',
        'Wrong_Phone' => 'wrong_phone',
        'Phone' => 'full_phone_number'
      ]
    end

    def membership_fieldmap(options)
      [ 
        'Membership_status' => 'status',
        'Terms_of_membership' => 'terms_of_membership_id',
        'Join_date' => 'join_date',
        'Cancel_date' => 'cancel_date',
        'Quota' => 'quota'
      ]
    end

    def enrollment_fieldmap(options)
      [ 
        'Marketing_code' => 'marketing_code',
        'Mega_channel' => 'mega_channel',
        'Fulfillment_code' => 'fulfillment_code',
        'Campaign_medium' => 'campaign_medium',
        'Product_sku' => 'product_sku',
        'Landing_URL' => 'landing_url',
        'Enrollment_amount' => 'enrollment_amount'
      ]
    end

    def aditional_fieldmap(options)
      [ 
        'Installment_amount' => '',
        'Refunded_amount' => ''
      ]
    end

  end
end

