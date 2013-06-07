module SacExactTarget
  class Prospect < Struct.new(:prospect)
    def save!
      unless self.prospect.email.include?('@noemail.com') # do not sync @noemail.com
        begin
          client = ExactTargetSDK::Client.new
          list = ExactTargetSDK::Lists.new(ID: self.club.marketing_tool_attributes['et_prospect_list'])

          attributes = fields_map.collect do |api_field, our_field| 
            attributes << ExactTargetSDK::Attributes.new(Name: api_field, Value: self.send(our_field))
          end
          id = ExactTargetSDK::SubscriberClient.new(ID: business_unit_id)

          subscriber = ExactTargetSDK::Subscriber.new('SubscriberKey' => self.uuid, 
            'EmailAddress' => self.email, 'Client' => id, 'ObjectID' => true, 
            'Attributes' => attributes, 'List' => list)

          res = client.Create(subscriber)
        rescue Exception => e
          res = $!.to_s
          SacExactTarget.logger.info "  => #{$!.to_s}"
        ensure
          res
        end
      end
    end

    private
      def fields_map
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
          'Terms_of_membership' => 'terms_of_membership_id',
          'Marketing_code' => 'marketing_code',
          'Mega_channel' => 'mega_channel',
          'Fulfillment_code' => 'fulfillment_code',
          'Campaign_medium' => 'campaign_medium',
          'Product_sku' => 'product_sku',
          'Landing_URL' => 'landing_url',
          'Phone' => 'full_phone_number'
          'Gender' => 'gender'
          # 'Member_since_date' => '',
          # 'Installment_amount' => '',
          # 'External_id' => '',
        ]
      end
      def business_unit_id
        Rails.env == 'production' ? self.club.marketing_tool_attributes['et_business_unit'] : Settings.exact_target.business_unit_for_test
      end
  end
end



