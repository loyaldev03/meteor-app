module Pardot
  class Member < Struct.new(:member)

    # We dont check if a field changed, because we do this sync after drupal sync. Drupal sync saves object making changes hash to be empty.
    MEMBER_OBSERVED_FIELDS = %w(first_name last_name address city email phone_country_code phone_area_code phone_local_number state zip visible_id birth_date blacklisted preferences status member_since_date wrong_address wrong_phone_number bill_date gender external_id autologin_url country member_group_type_id club_cash_amount).to_set.freeze
    MEMBERSHIP_OBSERVED_FIELDS = %w(terms_of_membership join_date cancel_date quota).to_set.freeze
    ENROLLMENT_INFO_OBSERVED_FIELDS = %w(joint marketing_code mega_channel fulfillment_code campaign_medium_version campaign_medium product_sku landing_url enrollment_amount).to_set.freeze

    def save!
      unless self.member.email.include?('@noemail.com') # do not sync @noemail.com
        begin
          res = conn.prospects.upsert_by_email(CGI.escape(self.member.email), fieldmap)
          Pardot.logger.debug "Pardot answer: " + res.inspect
        rescue Exception => e
          res = $!.to_s
          Pardot.logger.info "  => #{$!.to_s}"
        ensure
          update_member(res)
          res
        end
      end
    end

    def new_record?
      self.member.pardot_id.nil?
    end

  private

    # will raise a Pardot::ResponseError if login fails
    # will raise a Pardot::NetError if the http call fails
    def conn
      c = self.member.club.pardot
      c.authenticate
      c
    end

    def update_member(res, destroy = false)
      data = if res.class == Hash and res.has_key? 'id'
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
      cm = m.current_membership
      map = {
        first_name: m.first_name,
        last_name: m.last_name,
        email: m.email,
        address_one: m.address,
        city: m.city,
        state: m.state,
        zip: m.zip,
        country: m.country,
        phone: m.full_phone_number,
        opted_out: (m.blacklisted ? 1 : 0),
        birth_date: m.birth_date,
        preferences: m.preferences,
        gender: m.gender,
        status: m.status.capitalize,
        member_since_date: m.member_since_date,
        wrong_address: (m.wrong_address ? 1 : 0),
        wrong_phone_number: (m.wrong_phone_number ? 1 : 0),
        external_id: m.external_id,
        club_cash_amount: m.club_cash_amount,
        autologin_url: m.autologin_url,
        member_number: m.visible_id,
        club: m.club.name,
        client: m.club.partner.name,
        next_bill_date: m.bill_date
      }

      unless m.member_group_type_id.nil?
        map.merge!({ member_group_type: m.member_group_type.name })
      end

      unless cm.nil?
        e = cm.enrollment_info
        unless e.nil?
          map.merge!({
            marketing_code: e.marketing_code.capitalize,
            mega_channel: e.mega_channel.capitalize,
            joint: (e.joint ? 1 : 0),
            fulfillment_code: e.fulfillment_code,
            campaign_medium_version: e.campaign_medium_version,
            campaign_medium: e.campaign_medium.capitalize,
            product_sku: e.product_sku,
            landing_url: e.landing_url,
            enrollment_amount: "%.2f" % e.enrollment_amount
          })
        end
        map.merge!({ 
          installment_amount: "%.2f" % cm.terms_of_membership.installment_amount,
          terms_of_membership_id: cm.terms_of_membership_id,
          quota: cm.quota,
          join_date: cm.join_date,
          cancel_date: cm.cancel_date
        })
      end
      
      Pardot.logger.debug "Pardot JSON request: " + map.inspect
      map
    end
  end
end



