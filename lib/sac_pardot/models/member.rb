module Pardot
  class Member < Struct.new(:member)
    MEMBER_OBSERVED_FIELDS = %w(first_name last_name address city email phone_country_code phone_area_code phone_local_number state zip visible_id birth_date blacklisted preferences status member_since_date wrong_address wrong_phone_number joint next_bill_date).to_set.freeze
    MEMBERSHIP_OBSERVED_FIELDS = %w(terms_of_membership join_date cancel_date).to_set.freeze
    ENROLLMENT_INFO_OBSERVED_FIELDS = %w(marketing_code mega_channel fulfillment_code campaign_medium_version campaign_medium product_sku landing_url enrollment_amount).to_set.freeze

    def save!(options = {})
      if options[:force] || sync_fields.present? # change tracking
        unless self.member.email.include?('@noemail.com') # do not sync @noemail.com
          begin
            res = conn.prospects.upsert_by_email(CGI.escape(self.member.email), fieldmap)
            Pardot.logger.debug res
          rescue Exception => e
            res = $!.to_s
            Pardot.logger.info "  => #{$!.to_s}"
          ensure
            update_member(res)
            res
          end
        end
      end
    end

    def new_record?
      self.member.pardot_id.nil?
    end

  private
    def sync_fields
      MEMBER_OBSERVED_FIELDS.intersection(self.member.changed)
    end

    def conn
      self.member.club.pardot
    end

    def update_member(res, destroy = false)
      data = if res.has_key? 'id'
        { 
          pardot_id: res['id'],
          pardot_last_synced_at: Time.zone.now,
          pardot_synced_status: 'synced',
          pardot_last_sync_error: nil,
          pardot_last_sync_error_at: nil
        }
      else
        {
          pardot_last_sync_error: res,
          pardot_synced_status: 'error',
          pardot_last_sync_error_at: Time.zone.now
        }
      end
      ::Member.where(uuid: self.member.uuid).limit(1).update_all(data)
      self.member.reload rescue self.member
    end

    def fieldmap
      m = self.member
      map = {
        first_name: m.first_name,
        last_name: m.last_name,
        email: m.email,
        address_one: m.address,
        city: m.city,
        state: m.state,
        zip: m.zip,
        country: m.country,
        phone_number: m.full_phone_number,
        opted_out: m.blacklisted,
        birth_date: m.birth_date,
        preferences: m.preferences,
        gender: m.gender,
        status: m.status,
        terms_of_membership: m.terms_of_membership_id,
        member_since_date: m.member_since_date,
        wrong_address: m.wrong_address,
        wrong_phone_number: m.wrong_phone_number,
        join_date: m.join_date,
        joint: m.joint,
        cancel_date: m.cancel_date,
        next_bill_date: m.bill_date,
        marketing_code: m.current_membership.enrollment_info.marketing_code,
        mega_channel: m.current_membership.enrollment_info.mega_channel,
        fulfillment_code: m.current_membership.enrollment_info.fulfillment_code,
        campaign_medium_version: m.current_membership.enrollment_info.campaign_medium_version,
        campaign_medium: m.current_membership.enrollment_info.campaign_medium,
        product_sku: m.current_membership.enrollment_info.product_sku,
        landing_url: m.current_membership.enrollment_info.landing_url,
        enrollment_amount: m.current_membership.enrollment_info.enrollment_amount,
        installment_amount: m.terms_of_membership.installment_amount
      }
      if self.new_record?
        map.merge!({
          uuid: m.uuid,
          visible_id: m.visible_id,
          club: m.club_id,
          client: m.club.partner_id,
        })
      end
      map
    end
  end
end



