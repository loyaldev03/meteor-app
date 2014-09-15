module SacExactTarget
  class ProspectModel < Struct.new(:prospect)

    def save!(club = nil)
      return unless self.prospect.email
      setup_club(club)
      # Find by email . I didnt have luck looking for a subscriber by email and List.
      subscriber = SacExactTarget::ProspectModel.find_by_email self.prospect.email, club_id
      res = if subscriber.nil?
        begin 
          options = { :subscribe_to_list => true }
          client.Create(subscriber(subscriber_key, options))
        rescue Exception => e
          Auditory.audit(nil, self.prospect, e, User.find_by_email_and_club_id(self.prospect.email,self.prospect.club_id), Settings.operation_types.et_timeout_create) if e.to_s.include?("Timeout")
          raise e
        end
      elsif SacExactTarget::ProspectModel.email_belongs_to_prospect?(subscriber.subscriber_key)
        begin
          options = { :subscribe_to_list => false }
          client.Update(subscriber(subscriber.subscriber_key, options))
        rescue Exception => e
          Auditory.audit(nil, self.prospect, e, User.find_by_email_and_club_id(self.prospect.email,self.prospect.club_id), Settings.operation_types.et_timeout_update) if e.to_s.include?("Timeout")
          raise e
        end
      end
      update_prospect(res)
    end

    def self.destroy_by_email!(email, club_id)
      subscribers = find_all_by_email!(email, club_id)
      unless subscribers.empty?
        subscribers.each do |subscriber|
          prospect = email_belongs_to_prospect?(subscriber.subscriber_key)
          prospect.exact_target_prospect.destroy! unless prospect.nil?
        end
      end
    end

    def destroy!
      subscriber = ExactTargetSDK::Subscriber.new('SubscriberKey' => subscriber_key, 
        'EmailAddress' => self.prospect.email, 'ObjectID' => true)
      res = client.Delete(subscriber)
      SacExactTarget::report_error("SacExactTarget:Prospect:destroy", res) if res.OverallStatus != "OK"
    rescue Exception => e 
      Auditory.audit(nil, self.prospect, e, User.find_by_email_and_club_id(self.prospect.email,self.prospect.club_id), Settings.operation_types.et_timeout_destroy) if e.to_s.include?("Timeout")
      raise e
    end

    def self.find_all_by_email!(email, club_id)
      # Find by email . I didnt have luck looking for a subscriber by email and List.
      res = ExactTargetSDK::Subscriber.find [ ["EmailAddress", ExactTargetSDK::SimpleOperator::EQUALS, email] ]
      res.Results.collect do |result|
        result.attributes.select {|d| d == { :name => "Club", :value => club_id } }.empty? ? nil : result
      end.flatten.compact
    rescue Exception => e
      Auditory.audit(nil, nil, e, User.find_by_email_and_club_id(email,club_id), Settings.operation_types.et_timeout_find) if e.to_s.include?("Timeout")
      raise e
    end

    def self.find_by_email(email, club_id)
      find_all_by_email!(email, club_id).first
    end
 
    # easy way to know if a subscriber key is a prospect or member. This method can be improved, filtering by List id.
    # If subscriber is prospct we will find him. If its a member, subscriber key is the member id, 
    # so, it wont be find it on prospect table
    def self.email_belongs_to_prospect?(subscriber_key)
      if Rails.env.production?
        Prospect.find_by_uuid subscriber_key
      else
        Prospect.find_by_uuid subscriber_key.gsub(/(staging-|prototype-)/, '')
      end
    end

    def update_prospect(res)
      data = {}
      unless res.nil?
        data = if res.OverallStatus != "OK"
          SacExactTarget::report_error("SacExactTarget:Prospect:save", res)
          { marketing_client_sync_result: res.Results.first.status_message }
        else
          { marketing_client_sync_result: 'Success' }
        end
      end
      data = data.merge(need_sync_to_marketing_client: false)
      ::Prospect.where(uuid: self.prospect.uuid).limit(1).update_all(data)
      self.prospect.reload rescue self.prospect
    end
 
    def setup_club(club)
      @club = club.nil? ? self.prospect.club : club
    end
 
    private

      def client
        ExactTargetSDK::Client.new
      end

      def client_id
        ExactTargetSDK::SubscriberClient.new(ID: business_unit_id)
      end
    
      def subscriber_key
        Rails.env.production? ? self.prospect.uuid : "#{Rails.env}-#{self.prospect.uuid.to_s}"
      end

      def subscriber(subscriber_key, options ={})
        attributes, list =  [], [ ExactTargetSDK::List.new(ID: @club.marketing_tool_attributes['et_prospect_list'] , Status: 'Active', Action: 'create') ]
        fields_map.collect do |api_field, our_field| 
          attributes << SacExactTarget.format_attribute(self.prospect, api_field, our_field)
        end
        if Rails.env.production?
          if self.prospect.preferences and preference_fields_map
            preference_fields_map.collect do |api_field, our_field|
              attributes << ExactTargetSDK::Attributes.new(Name: api_field, Value: self.prospect.preferences[our_field].to_s)
            end
          end
        end
        attributes << ExactTargetSDK::Attributes.new(Name: 'Club', Value: club_id)
        ExactTargetSDK::Subscriber.new({
          'SubscriberKey' => subscriber_key, 
          'EmailAddress' => self.prospect.email, 'Client' => client_id, 'ObjectID' => true, 
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

      def preference_fields_map
        case self.prospect.club_id
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

      def club_id
        Rails.env.production? ? @club.id.to_s : '9999'
      end

      def business_unit_id
        Rails.env.production? ? @club.marketing_tool_attributes['et_business_unit'] : Settings.exact_target.business_unit_for_test
      end
  end
end



