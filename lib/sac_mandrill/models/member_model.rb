  module SacMandrill
  class MemberModel < Struct.new(:user)

    def send_email(template_name, subaccount)
      message = {"to" => [{ "email" => self.user.email }]}
      message.merge!({ "global_merge_vars" => subscriber_variables })
      message.merge!({ "subaccount" => subaccount }) unless subaccount.blank?
      template_content = {}
      result = client.messages.send_template template_name, template_content, message
      result.first
    rescue Exception => e
      Auditory.audit(nil, self.user, e, self.user, Settings.operation_types.mandrill_timeout_trigger_create) if e.to_s.include?("Timeout")
      raise e
    end

    def subscriber_variables
      attributes = []
      fieldmap.each do |api_field, our_field| 
        attributes << SacMandrill.format_attribute(self.user, api_field, our_field)
      end
      membership = self.user.current_membership
      membership_fieldmap.each do |api_field, our_field| 
        attributes << SacMandrill.format_attribute(membership, api_field, our_field)
      end
      terms_of_membership = membership.terms_of_membership
      terms_of_membership_fieldmap.each do |api_field, our_field| 
        attributes << SacMandrill.format_attribute(terms_of_membership, api_field, our_field)
      end
      if self.user.preferences and preferences_fieldmap
        member_preferences = self.user.user_preferences
        preferences_fieldmap.each do |api_field, our_field|
          attributes << {"name" => api_field, "content" => self.user.preferences[our_field].to_s}
        end
      end
      attributes
    end

    #If any of these variables are changed, please check Mailchimp's variable too.
    def fieldmap
      { 
        'MEMBERID' => 'id',
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
        'PHONE' => 'full_phone_number',
        'CJOINDATE' => 'current_join_date',
        'VIPMEMBER' => 'vip_member'
      }
    end

    def membership_fieldmap
      {
        'STATUS' => 'status',
        'TOMID' => 'terms_of_membership_id',
        'JOINDATE' => 'join_date',
        'CANCELDATE' => 'cancel_date',
        'AUDIENCE' => 'audience',
        'CTYPE' => 'utm_campaign',
        'CAMPAIGNID' => 'campaign_code',
        'MEDIUM' => 'utm_medium',
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
      Settings['club_params'][user.club_id]['preferences']
    rescue NoMethodError => e
      Auditory.audit(nil, user.club, I18n.t('error_messages.preferences_not_set_for_club') + " - #{e}")
    end

    def client
      @mandrill ||= Mandrill::API.new self.user.club.marketing_tool_attributes["mandrill_api_key"]
    end
  end
end
