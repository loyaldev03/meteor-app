module Drupal
  class Member < Struct.new(:member)

    def get
      res = conn.get('/api/user/%{drupal_id}' % { drupal_id: self.member.api_id }).body unless self.new_record?
      rescue Faraday::Error::ParsingError # Drupal sends invalid application/json when something goes wrong
        Drupal.logger.info "  => #{$!.to_s}"
      ensure
        res
    end

    def update!
      if self.member.changed.present? # change tracking
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

    def create!
      res = conn.post '/api/user', fieldmap
      update_member(res)
    end

    def save!
      self.new_record? ? self.create! : self.update!
    end

    def destroy!
      res = conn.delete('/api/user/%{drupal_id}' % { drupal_id: self.member.api_id }) unless self.member.new_record?
    rescue Faraday::Error::ParsingError # Drupal sends invalid application/json
      Drupal.logger.info "  => #{$!.to_s}"
    ensure
      # update_member(res)
      res
    end

    def new_record?
      self.member.api_id.nil?
    end

    def login_token
      @token ||= Hashie::Mash.new(conn.get('/api/urllogin/%{drupal_id}'% { drupal_id: self.member.api_id }).body) unless self.new_record?
    end

    def reset_password!
      conn.post('/api/user/%{drupal_id}/password_reset'% { drupal_id: self.member.api_id })
    end

    def resend_welcome_email!
      raise 'tbd -- once drupal sends welcome email we can trigger it'
    end

  private
    def conn
      self.member.club.drupal
    end

    def update_member(res)
      if res
        data = if res.status == 200
          { 
            api_id: res.body['uid'],
            last_synced_at: Time.now,
            last_sync_error: nil
          }
        else
          {
            last_sync_error: res.body
          }
        end
        ::Member.where(uuid: self.member.uuid).limit(1).update_all(data)
        self.member.reload rescue self.member
      end
    end

    def fieldmap(full = false)
      m = self.member

      map = { 
        name: m.full_name,
        mail: m.email,
        pass: SecureRandom.hex, 
        field_profile_address: { 
          und: [ 
            { 
              value: m.address
            } 
          ] 
        }, 
        field_profile_firstname: { 
          und: [ 
            { 
              value: m.first_name
            } 
          ] 
        }, 
        field_profile_lastname: { 
          und: [ 
            { 
              value: m.last_name
            } 
          ] 
        }, 
        field_profile_city: { 
          und: [ 
            { 
              value: m.city
            } 
          ] 
        }, 
        field_profile_phone: { 
          und: [ 
            { 
              value: m.phone_number
            } 
          ] 
        }, 
        field_profile_state_province: { 
          und: { 
            value: m.state
          } 
        }, 
        field_profile_zip: { 
          und: [ 
            {
              value: m.zip
            } 
          ] 
        } 
      }

      unless m.new_record?
        map.merge!({
          field_profile_member_id: { 
            und: [ 
              {
                value: m.reload.visible_id
              } 
            ] 
          }
        })
      end

      cc = m.active_credit_card
      if false && cc
        map.merge!({
          field_profile_cc_month: {
            und: {
              value: cc.expire_month.to_s
            }
          },
          field_profile_cc_year: {
            und: {
              value: cc.expire_year.to_s
            }
          },
          field_profile_cc_number: {
            und: {
              value: cc.number.to_s
            }
          }
        })
      end

      map
    end
  end
end