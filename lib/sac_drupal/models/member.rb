module Drupal
  class Member < Struct.new(:member)
    OBSERVED_FIELDS = %w(first_name last_name gender address city email phone_country_code phone_area_code phone_local_number state zip country id type_of_phone_number birth_date type_of_phone_number club_cash_amount next_retry_bill_date).to_set.freeze

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

    def destroy!
      res = conn.post('/api/user/%{drupal_id}/cancel' % { drupal_id: self.member.api_id }) unless self.member.new_record?
    rescue Faraday::Error::ParsingError # Drupal sends invalid application/json
      Drupal.logger.info "  => #{$!.to_s}"
    ensure
      update_member(res, true)
      res
    end

    def new_record?
      self.member.api_id.nil?
    end

    def login_token(options = {})
      if @token.nil? || options[:force]
        @token = Hashie::Mash.new(conn.get('/api/urllogin/%{drupal_id}' % { drupal_id: self.member.api_id }).body) unless self.new_record?
      end
      uri = @token && @token.url && URI.parse(@token.url)
      self.member.update_column :autologin_url, uri.path if uri
      @token
    rescue Exception => e
      Auditory.report_issue('Drupal:Member:login_token', e, { :member => self.member.inspect })
      nil
    end

    def reset_password!
      res = conn.post('/api/user/%{drupal_id}/password_reset' % { drupal_id: self.member.api_id })
      res.success?
    end

    def resend_welcome_email!
      res = conn.post('/api/user/%{drupal_id}/resend_welcome_email' % { drupal_id: self.member.api_id })
      res.success?
    end

  private
    def sync_fields
      OBSERVED_FIELDS.intersection(self.member.changed)
    end

    def conn
      self.member.club.drupal
    end

    def update_member(res, destroy = false)
      if res
        data = if res.status == 200
          { 
            api_id: ( destroy ? nil : res.body['uid'] ),
            last_synced_at: Time.now,
            last_sync_error: nil,
            last_sync_error_at: nil,
            sync_status: "synced"
          }
        else
          {
            last_sync_error: res.body.class == Hash ? res.body["form_errors"].inspect : res.body,
            last_sync_error_at: Time.now,
            sync_status: "with_error"
          }
        end
        ::Member.where(id: self.member.id).limit(1).update_all(data)
        self.member.reload rescue self.member
      end
    end

    def fieldmap
      m = self.member

      role_list = {}
      m.current_membership.terms_of_membership.api_role.to_s.split(',').each do |role|
        role_list = role_list.merge!({role => role})
      end

      map = { 
        mail: m.email,
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
        field_profile_gender: { 
          und: { select: (m.gender.blank? ? "_none" : m.gender) }
        },
        field_profile_phone_type: { 
          und: ( 
              m.type_of_phone_number.blank? ? { "select" => "_none" } : ( 
                m.type_of_phone_number.downcase == 'other' ? { "select" => "select_or_other", "other" => m.type_of_phone_number.downcase } : { "select" => m.type_of_phone_number.downcase }
              ) 
            )
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
        field_profile_club_cash_amount: { 
          und: [{ value: m.club_cash_amount }]
        },
        field_profile_dob: {
          und: [
            {
              value: { date: (m.birth_date.nil? ? '' : m.birth_date.to_date.strftime("%m/%d/%Y")) }
            }
          ]
        },
        field_profile_address_address:{
          und:[ 
            {
              country: m.country,
              administrative_area: m.state,
              locality: m.city,
              postal_code: m.zip,
              thoroughfare: m.address
            } 
          ]
        },
        field_profile_billing_date:{
          und: [
            {
              value: { date: (m.next_retry_bill_date.nil? ? '' : m.next_retry_bill_date.to_date.strftime("%m/%d/%Y")) }
            }
          ]          
        }
        roles: role_list,
      }

      if self.new_record?
        map.merge!({
          pass: SecureRandom.hex, 
          field_phoenix_member_id: {
            und: [ { value: m.id } ]
          }
        })
      else
        map.merge!({
          field_profile_member_id: { 
            und: [ { value: m.reload.id } ] 
          }
        })
      end

      # Add credit card information
      cc = m.active_credit_card
      if cc and (self.new_record? or (not self.new_record? and not cc.expired?))
        map.merge!({
          field_profile_cc_month: {
            und: { value: "%02d" % cc.expire_month.to_s }
          },
          field_profile_cc_year: {
            und: { value: cc.expire_year.to_s }
          },
          field_profile_cc_number: {
            und: [{
              value: "XXXX-XXXX-XXXX-%{last_digits}" % { last_digits: cc.last_digits }
            }]
          }
        })
      end

      # Add dynamyc preferences.
      unless m.preferences.nil?
        m.preferences.each do |key, value|
          map.merge!({
            "field_phoenix_pref_#{key}" =>  {
              und: ( value.nil? ? { "select" => "_none" } : { "select" => value } )
            }
          })
        end
      end
      map
    end
  end
end