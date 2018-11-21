module Spree
  class Member < Struct.new(:user)
    OBSERVED_FIELDS = %w(email club_cash_amount status current_membership_id vip_member).to_set.freeze

    def update!(options = {})
      res = conn.put "/api/v1/users/#{self.user.api_id}/update_account", fieldmap
      update_user(res)
    end

    def create!(options = {})
      res = conn.post '/api/v1/users/create_account', fieldmap
      update_user(res)
    end

    def save!(options = {})
      if self.user.can_be_synced_to_remote? # Bug #23017 - skip sync if lapsed or applied.
        new_record? ? self.create!(options) : self.update!(options)
      end
    end
    
    def reset_password!
      res = conn.post("/api/v1/users/#{self.user.api_id}/resend_reset_password_instructions")
      res.success?
    end

    def resend_welcome_email!
      res = conn.post("/api/v1/users/#{self.user.api_id}/resend_welcome_email")
      res.success?
    end

    def destroy!
      res = conn.put("/api/v1/users/#{self.user.api_id}/delete_account") unless self.user.new_record?
      update_user(res, true)
      res
    end

    def login_token
      res = Hashie::Mash.new(conn.post("/api/v1/users/#{self.user.api_id}/generate_urllogin").body)
      self.user.update_column :autologin_url, res.url
      res
    rescue
      Auditory.report_issue('Spree:Member:login_token', e, { :member => self.user.id })
      nil
    end

    def fieldmap
      role = if user.vip_member?
        'vip_member'
      elsif user.lapsed?
        'cancelled_member'
      elsif user.terms_of_membership.api_role.to_i == 6
        'standard_member'
      elsif user.terms_of_membership.api_role.to_i == 7
        'limited_access'
      end

      map = { 
        email: self.user.email,
        member_id: self.user.reload.id,
        preferences: self.user.preferences,
        vip_event_quota: self.user.club_cash_amount,
        role: role
      }
      
      map
    end
    
    private
    def new_record?
      self.user.api_id.nil?
    end
    
    def conn
      self.user.club.spree
    end
    
    def update_user(res, destroy = false)
      if res
        body = res.body
        data = if res.status == 200
          { 
            api_id: ( destroy ? nil : body["uid"] ),
            last_synced_at: Time.now,
            last_sync_error: nil,
            last_sync_error_at: nil,
            sync_status: "synced"
          }
        else
          {
            last_sync_error: "#{body['message']} #{body['errors']}",
            last_sync_error_at: Time.now,
            sync_status: "with_error"
          }
        end
        data.merge!({autologin_url: body["urllogin"]}) if body["urllogin"]
        ::User.where(id: self.user.id).limit(1).update_all(data)
        self.user.reload rescue self.user
      end
    end
    
  end
end