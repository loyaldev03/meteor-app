module SacExactTarget
  class Member < Struct.new(:member)
    def update!(options = {})
      if options[:force] || sync_fields.present? # change tracking
        begin
          res = conn.put('/api/user/%{drupal_id}' % { drupal_id: self.member.api_id }, fieldmap)
        rescue Faraday::Error::ParsingError # Drupal sends invalid application/json when something goes wrong
          Drupal.logger.info "  => #{$!.to_s}"
        ensure
          update_member(res)
          res
        end
      end
    end

    def create!(options = {})
      res = conn.post '/api/user', fieldmap
      update_member(res)
      if res and res.status == 200
        @token = Hashie::Mash.new(res.body['urllogin'])
        login_token
      end
    end

    def save!(options = {})
      if self.member.can_be_synced_to_remote? # Bug #23017 - skip sync if lapsed or applied.
        self.new_record? ? self.create!(options) : self.update!(options)
      end
    end

    def new_record?
      self.member.pardot_id.nil?
    end

  private

    # will raise a SacExactTarget::ResponseError if login fails
    # will raise a SacExactTarget::NetError if the http call fails
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
      ::Member.where(id: self.member.id).limit(1).update_all(data)
      self.member.reload rescue self.member
    end

    def fieldmap(options)
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

