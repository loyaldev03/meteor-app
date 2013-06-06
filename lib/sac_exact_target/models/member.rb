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
      SacExactTarget.logger.debug "Pardot JSON request: " + map.inspect
      map
    end
  end
end

