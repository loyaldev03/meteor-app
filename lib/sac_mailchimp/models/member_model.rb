module SacMailchimp
	class MemberModel < Struct.new(:user)

    def save!
      if has_fake_email? 
        res = Gibbon::MailChimpError.new('invalid email', { body: {'status' => 100}, title: 'Synchronization canceled.', detail: "Email address looks fake or invalid." })
      else
        res = new_record? ? create! : update!
      end
      update_member(res)
    end

    def new_record?
      # Find by subscriber key. We can search by email, euid or leid. euid is an ID attached to the email, it means it changes when the email changes. leid is an ID attached to the subscriber, it does not change when the email is updated.
      # We are serching by leid, which is the ID attached to the subscriber.
      # Gibbon::Retrieve raise the followingexception when the subscriber is not found: Gibbon::MailChimpError: the server responded with status 404
      subscriber.blank?
    rescue Gibbon::MailChimpError => e
      update_member e
      raise e
    end

    def unsubscribe!
    	begin
        return if has_fake_email?
        save!
      rescue Gibbon::MailChimpError => e
        update_member e
        raise e
    	end
    end

    def delete!
      return if has_fake_email?
      if (client.lists(mailchimp_list_id).members(email).retrieve rescue nil)
        client.lists(mailchimp_list_id).members(email).delete
      end
    rescue Gibbon::MailChimpError => e
      SacMailchimp::report_error("Member:testing_account_delete", e, self.user)
    end

    def update_email!(former_email)
      unless has_fake_email?(former_email)
        former_subscriber = client.lists(mailchimp_list_id).members(email(former_email)).retrieve rescue nil
        if former_subscriber
          begin
            client.lists(mailchimp_list_id).members(email(former_email)).delete
          rescue Gibbon::MailChimpError => e
            SacMailchimp::report_error("Member:mailchimp_update_email", e, self.user)
          end
        end
      end
      subscribe!
    end

    def subscribe!
      save!
    rescue Gibbon::MailChimpError => e
      update_member e
      SacMailchimp::report_error("Member:mailchimp_subscribe", e, self.user)
    end

    def create!
      begin
        client.lists(mailchimp_list_id).members.create(body: { email_address: self.user.email.downcase, status: subscriber_status, merge_fields: subscriber_data })
      rescue Gibbon::MailChimpError => e
        handle_exception_upon_sync e
      end
    end

    def update!
    	begin
        data = { body: { status: subscriber_status , merge_fields:  subscriber_data } }
        client.lists(mailchimp_list_id).members(email).update(data)
      rescue Gibbon::MailChimpError => e
        handle_exception_upon_sync e
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
          marketing_client_last_sync_error: "#{res.title}: #{res.detail}".truncate(255),
          marketing_client_last_sync_error_at: Time.zone.now
        }
      else
        {
          marketing_client_last_synced_at: Time.zone.now,
          marketing_client_synced_status: 'synced',
          marketing_client_last_sync_error: nil,
          marketing_client_last_sync_error_at: nil,
        }
      end
      additional_data = if res.instance_of?(Gibbon::MailChimpError) and res.body.nil?
        { need_sync_to_marketing_client: true }
      else
        { need_sync_to_marketing_client: false }
      end
      data.merge! additional_data
      ::User.where(id: self.user.id).limit(1).update_all(data)
      self.user.reload rescue self.user
    end

    def subscriber_data
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
      if self.user.preferences and preferences_fieldmap
        member_preferences = self.user.user_preferences
        preferences_fieldmap.each do |api_field, our_field|
          attributes.merge!({ api_field => self.user.preferences[our_field].to_s })
        end
      end
			attributes
    end

    #If any of these variables are changed, please check Mandrill's variable too.
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
      Gibbon::Request.new
    end

    def email(subscriber_email = nil)
      Digest::MD5.hexdigest( (subscriber_email || self.user.email).downcase )
    end

    def subscriber
      @subscriber = client.lists(mailchimp_list_id).members(email).retrieve rescue nil
    end

    def subscriber_status
      self.user.lapsed? ? 'unsubscribed' : 'subscribed'
    end

    def mailchimp_list_id
    	@list_id ||= self.user.club.marketing_tool_attributes["mailchimp_list_id"]
    end
    
    def handle_exception_upon_sync(exception)
      update_member exception
      raise exception unless exception.detail.include? SacMailchimp::MULTIPLE_SIGNED_ERROR_MESSAGE
    end

    def has_fake_email?(subscriber_email = nil)
      ['mailinator.com', 'test.com', 'noemail.com'].include? (subscriber_email || self.user.email).downcase.split('@')[1]
    end
	end
end
