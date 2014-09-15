module Pardot
  class Member < Struct.new(:user)
    def save!(options = {})
      unless self.user.email.include?('@noemail.com') # do not sync @noemail.com
        begin
          res = conn.prospects.upsert_by_email(CGI.escape(self.user.email), fieldmap(options))
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
      self.user.marketing_client_id.nil?
    end

  private

    # will raise a Pardot::ResponseError if login fails
    # will raise a Pardot::NetError if the http call fails
    def conn
      c = self.user.club.pardot
      c.authenticate
      c
    end

    def update_member(res, destroy = false)
      data = if res.class == Hash and res.has_key? 'id'
        { 
          marketing_client_id: res['id'],
          marketing_client_last_synced_at: Time.zone.now,
          marketing_client_synced_status: 'synced',
          marketing_client_last_sync_error: nil,
          marketing_client_last_sync_error_at: nil
        }
      else
        {
          marketing_client_last_sync_error: res,
          marketing_client_synced_status: 'error',
          marketing_client_last_sync_error_at: Time.zone.now
        }
      end
      ::User.where(id: self.user.id).limit(1).update_all(data)
      self.user.reload rescue self.user
    end

    def fieldmap(options)
      m = self.user
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
        phone: m.phone_area_code.to_s+'-'+m.phone_local_number.to_s[0..2]+'-'+m.phone_local_number.to_s[-4..-1],
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
        member_number: m.id,
        club: m.club.name,
        client: m.club.partner.name,
        next_bill_date: m.bill_date
      }

      unless m.member_group_type_id.nil?
        map.merge!({ member_group_type: m.member_group_type.name })
      end

      unless options.empty?
        map.merge!(options)
      end

      unless cm.nil?
        e = cm.enrollment_info
        unless e.nil?
          map.merge!({
            marketing_code: e.marketing_code.to_s.capitalize,
            mega_channel: e.mega_channel.to_s.capitalize,
            joint: (e.joint ? 1 : 0),
            fulfillment_code: e.fulfillment_code,
            campaign_medium_version: e.campaign_medium_version,
            campaign_medium: e.campaign_medium.to_s.capitalize,
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

