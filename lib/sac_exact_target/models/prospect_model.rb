module SacExactTarget
  class ProspectModel < Struct.new(:prospect)
    def save!
      return unless self.prospect.email
      client, options = ExactTargetSDK::Client.new, {}
      # Find by email . I didnt have luck looking for a subscriber by email and List.
      subscriber = SacExactTarget::ProspectModel.find_by_email self.prospect.email, club_id
      res = if subscriber.nil?
        options[:subscribe_to_list] = true
        client.Create(subscriber(subscriber_key, options))
      elsif SacExactTarget::ProspectModel.email_belongs_to_prospect?(subscriber.subscriber_key)
        options[:subscribe_to_list] = false
        client.Update(subscriber(subscriber.subscriber_key, options))
      end
      update_prospect(res) unless res.nil?
    end

    def self.destroy_by_email(email, club_id)
      subscriber = find_by_email(email, club_id)
      if not subscriber.nil? and not (prospect = email_belongs_to_prospect?(subscriber.subscriber_key)).nil?
        prospect.exact_target_prospect.destroy!
      end
    end

    def destroy!
      client = ExactTargetSDK::Client.new
      subscriber = ExactTargetSDK::Subscriber.new('SubscriberKey' => subscriber_key, 
        'EmailAddress' => self.prospect.email, 'ObjectID' => true)
      res = client.Delete(subscriber)
      SacExactTarget::report_error("SacExactTarget:Prospect:destroy", res)
    end

    def self.find_by_email(email, club_id)
      # Find by email . I didnt have luck looking for a subscriber by email and List.
      res = ExactTargetSDK::Subscriber.find [ ["EmailAddress", ExactTargetSDK::SimpleOperator::EQUALS, email] ]
      res.Results.collect do |result|
        result.attributes.select {|d| d == { :name => "Club", :value => club_id } }.empty? ? nil : result
      end.flatten.first
    end
 
    # easy way to know if a subscriber key is a prospect or member. This method can be improved, filtering by List id.
    # If subscriber is prospct we will find him. If its a member, subscriber key is the member id, 
    # so, it wont be find it on prospect table
    def self.email_belongs_to_prospect?(subscriber_key)
      if Rails.env.production?
        Prospect.find_by_uuid subscriber_key
      else
        Prospect.find_by_uuid subscriber_key.gsub(/[staging-|prototype-]/, '')
      end
    end

    def update_prospect(res)
      data = if res.OverallStatus != "OK"
        SacExactTarget::report_error("SacExactTarget:Member:save", res)
        { exact_target_sync_result: res.Results.first.status_message }
      else
        { exact_target_sync_result: 'Success' }
      end
      ::Prospect.where(uuid: self.prospect.id).limit(1).update_all(data)
      self.prospect.reload rescue self.prospect
    end

    private
      def subscriber_key
        Rails.env.production? ? self.prospect.uuid : "#{Rails.env}-#{self.prospect.uuid.to_s}"
      end

      def subscriber(subscriber_key, options ={})
        attributes, list =  [], [ ExactTargetSDK::List.new(ID: self.prospect.club.marketing_tool_attributes['et_prospect_list'], Status: 'Active', Action: 'create') ]
        fields_map.collect do |api_field, our_field| 
          attributes << SacExactTarget.format_attribute(self.prospect, api_field, our_field)
        end
        attributes << ExactTargetSDK::Attributes.new(Name: 'Club', Value: club_id)
        id = ExactTargetSDK::SubscriberClient.new(ID: business_unit_id)
        ExactTargetSDK::Subscriber.new({
          'SubscriberKey' => subscriber_key, 
          'EmailAddress' => self.prospect.email, 'Client' => id, 'ObjectID' => true, 
          'Attributes' => attributes.compact }.merge(options[:subscribe_to_list] ? { 'Lists' => list } : {} ))        
      end

      def fields_map
        {
          'First_name' => 'first_name',
          'Last_name' => 'last_name',
          'Address_one' => 'address',
          'City' => 'city',
          'State' => 'state',
          'Zip' => 'zip',
          'Country' => 'country',
          'Birth_date' => 'birth_date',
          'Terms_of_membership' => 'terms_of_membership_id',
          'Marketing_code' => 'marketing_code',
          'Mega_channel' => 'mega_channel',
          'Fulfillment_code' => 'fulfillment_code',
          'Campaign_medium' => 'campaign_medium',
          'Product_sku' => 'product_sku',
          'Landing_URL' => 'landing_url',
          'Phone' => 'full_phone_number',
          'Gender' => 'gender'
        }
      end

      def club_id
        Rails.env.production? ? self.prospect.club_id : '9999'
      end

      def business_unit_id
        Rails.env.production? ? self.club.marketing_tool_attributes['et_business_unit'] : Settings.exact_target.business_unit_for_test
      end
  end
end



