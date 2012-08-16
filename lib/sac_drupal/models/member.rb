module Drupal
  class Member < Struct.new(:member)
    OBSERVED_FIELDS = %w(first_name last_name address city email phone_number state zip country visible_id).to_set.freeze

    def get
      res = conn.get('/api/user/%{drupal_id}' % { drupal_id: self.member.api_id }).body unless self.new_record?
      rescue Faraday::Error::ParsingError # Drupal sends invalid application/json when something goes wrong
        Drupal.logger.info "  => #{$!.to_s}"
      ensure
        res
    end

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
      debugger
      update_member(res)
    end

    def save!(options = {})
      self.new_record? ? self.create!(options) : self.update!(options)
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

    def login_token(options = {})
      if @token.nil? || options[:force]
        @token = Hashie::Mash.new(conn.get('/api/urllogin/%{drupal_id}' % { drupal_id: self.member.api_id }).body) unless self.new_record?
      end

      uri = @token.url && URI.parse(@token.url)
      self.member.update_column :autologin_url, uri.path if uri
    end

    def reset_password!
      res = conn.post('/api/user/%{drupal_id}/password_reset' % { drupal_id: self.member.api_id })
      res.success?
    end

    def resend_welcome_email!
      raise 'tbd -- once drupal sends welcome email we can trigger it'
    end

  private
    def sync_fields
      OBSERVED_FIELDS.intersection(self.member.changed)
    end

    def conn
      self.member.club.drupal
    end

    def update_member(res)
      if res
        data = if res.status == 200
          { 
            api_id: res.body['uid'],
            last_synced_at: Time.now,
            last_sync_error: nil,
            last_sync_error_at: nil
          }
        else
          {
            last_sync_error: res.body.respond_to?(:[]) ? res.body[:message] : res.body,
            last_sync_error_at: Time.now
          }
        end
        ::Member.where(uuid: self.member.uuid).limit(1).update_all(data)
        self.member.reload rescue self.member
      end
    end

    def fieldmap
      m = self.member

      map = { 
        name: m.full_name,
        mail: m.email,
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
        field_profile_phone_type: { 
          und: [ 
            { 
              value: m.type_of_phone_number
            } 
          ] 
        },
        field_profile_phone_country_code: { 
          und: [ 
            { 
              value: m.phone_country_code
            } 
          ] 
        },
        field_profile_phone_area_code: { 
          und: [ 
            { 
              value: m.phone_area_code
            } 
          ] 
        },
        field_profile_phone_local_number: { 
          und: [ 
            { 
              value: m.phone_local_number
            } 
          ] 
        },
        field_profile_stateprovince: { 
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
        }, 
        field_profile_country: { 
          und: [ 
            {
              value: m.country
            } 
          ] 
        }  
      }

      if self.new_record?
        map.merge!({
          pass: SecureRandom.hex, 
        })
      else
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
      if cc
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