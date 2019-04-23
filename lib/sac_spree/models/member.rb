module Spree
  class Member < Struct.new(:user)
    OBSERVED_FIELDS = %w[email club_cash_amount status current_membership_id member_group_type_id first_name last_name preferences].to_set.freeze

    def update!
      res = conn.put "/api/v1/users/#{user.api_id}/update_account", fieldmap
      update_user(res)
    end

    def create!
      res = conn.post '/api/v1/users/create_account', fieldmap
      update_user(res)
    end

    def save!(*)
      if user.can_be_synced_to_remote? # Bug #23017 - skip sync if lapsed or applied.
        new_record? ? create! : update!
      end
    end

    def reset_password!
      res = conn.post("/api/v1/users/#{user.api_id}/resend_reset_password_instructions")
      res.success?
    end

    def resend_welcome_email!
      res = conn.post("/api/v1/users/#{user.api_id}/resend_welcome_email")
      res.success?
    end

    def destroy!
      res = conn.put("/api/v1/users/#{user.api_id}/delete_account") unless user.new_record?
      update_user(res, true)
      res
    end

    def login_token
      res = Hashie::Mash.new(conn.post("/api/v1/users/#{user.api_id}/generate_urllogin").body)
      user.update_column :autologin_url, res.url
      res
    rescue StandardError => e
      Auditory.report_issue('Spree:Member:login_token', e, member: user.id)
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
               'limited_access_member'
             end

      map = {
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        external_id: user.reload.id,
        preferences: user.preferences.present? ? user.preferences : {},
        vip_event_points: user.club_cash_amount,
        role: role
      }

      map
    end

    private

    def new_record?
      user.api_id.nil?
    end

    def conn
      user.club.spree
    end

    def update_user(res, destroy = false)
      if res
        body = res.body
        data = if res.status == 200
                 {
                   api_id: (destroy ? nil : body['uid']),
                   last_synced_at: Time.now,
                   last_sync_error: nil,
                   last_sync_error_at: nil,
                   sync_status: 'synced'
                 }
               else
                 {
                   last_sync_error: "#{body['message']} #{body['errors']}",
                   last_sync_error_at: Time.now,
                   sync_status: 'with_error'
                 }
               end
        data[:autologin_url] = body['urllogin'] if body['urllogin']
        ::User.where(id: user.id).limit(1).update_all(data)

        begin
          user.reload
        rescue StandardError
          user
        end
      end
    end
  end
end
