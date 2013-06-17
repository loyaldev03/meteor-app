module SacExactTarget
  class ProspectModel < Struct.new(:prospect)
    def save!
      return unless self.prospect.email
      client, options = ExactTargetSDK::Client.new, {}
      res = if must_create?
        options[:subscribe_to_list] = true
        client.Create(subscriber(self.prospect.uuid, options))
      elsif must_update?
        options[:subscribe_to_list] = false
        client.Update(subscriber(@subscriber.subscriber_key, options))
      end
      if res.OverallStatus != "OK"
        Auditory.report_issue("SacExactTarget:Prospect:save", res.Results.first.status_message, { :result => res.inspect })
      end
    end

    def destroy!
      client = ExactTargetSDK::Client.new
      subscriber = ExactTargetSDK::Subscriber.new('SubscriberKey' => self.prospect.uuid, 
        'EmailAddress' => self.prospect.email, 'ObjectID' => true)
      res = client.Delete(subscriber)
      if res.OverallStatus != "OK"
        Auditory.report_issue("SacExactTarget:Prospect:destroy", res.Results.first.status_message, { :result => res.inspect })
      end
    end

    # easy way to know if a subscriber key is a prospect or member. This method can be improved, filtering by List id.
    # If subscriber is prospct we will find him. If its a member, subscriber key is the member id, 
    # so, it wont be find it on prospect table
    def must_update?
      Prospect.find_by_uuid @subscriber.subscriber_key
    end

    def must_create?
      # Find by email . I didnt have luck looking for a subscriber by email and List.
      res = ExactTargetSDK::Subscriber.find [ ["EmailAddress", ExactTargetSDK::SimpleOperator::EQUALS, self.prospect.email] ]
      @subscriber = res.Results.collect do |result|
        result.attributes.select {|d| d == { :name => "Club", :value => club_id } }.empty? ? nil : result
      end.flatten.first
      @subscriber.nil?
    end

    private

      def subscriber(subscriber_key, options ={})
        list = [ ExactTargetSDK::List.new(ID: self.prospect.club.marketing_tool_attributes['et_prospect_list'], Status: 'Active', Action: 'create') ]
        attributes = fields_map.collect do |api_field, our_field| 
          ExactTargetSDK::Attributes.new(Name: api_field, Value: self.prospect.send(our_field)) unless self.prospect.send(our_field).blank?
        end.compact
        attributes << ExactTargetSDK::Attributes.new(Name: 'Club', Value: club_id)
        id = ExactTargetSDK::SubscriberClient.new(ID: business_unit_id)
        ExactTargetSDK::Subscriber.new({
          'SubscriberKey' => subscriber_key, 
          'EmailAddress' => self.prospect.email, 'Client' => id, 'ObjectID' => true, 
          'Attributes' => attributes }.merge(options[:subscribe_to_list] ? { 'Lists' => list } : {} ))        
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
        Rails.env == 'production' ? self.prospect.club_id : '9999'
      end
      def business_unit_id
        Rails.env == 'production' ? self.club.marketing_tool_attributes['et_business_unit'] : Settings.exact_target.business_unit_for_test
      end
  end
end



