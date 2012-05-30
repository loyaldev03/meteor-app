module Wordpress
  class Member < Struct.new(:member)
    # attribute: m.name
    # randomhex: SecureRandom.hex
    # profile: field_profile_name: { und: [ { value: m.name } ] }
    # profile_assoc: field_profile_name: { und: [ { value: m.assoc.name } ] } if m.assoc
    # profile_single: field_profile_name: { und: { value: m.name } }
    # FIELDS_MAP = [ ## WIP
    #   [:name,           :attribute,      :full_name],
    #   [:mail,           :attribute,      :email],
    #   [:pass,           :randomhex],
    #   [:address,        :profile,        :address],
    #   [:firstname,      :profile,        :first_name],
    #   [:lastname,       :profile,        :last_name],
    #   [:city,           :profile,        :city],
    #   [:phone,          :profile,        :phone_number],
    #   [:state_province, :profile_single, :state],
    #   [:zip,            :profile,        :zip],
    #   [:member_id,      :profile,        :visible_id],
    #   [:cc_month,       :profile_assoc,  :active_credit_card, :expire_month],
    #   [:cc_year,        :profile_assoc,  :active_credit_card, :expire_year],
    #   [:cc_number,      :profile_assoc,  :active_credit_card, :number]
    # ] 

    def get
      conn.get('/api/user/%{wordpress_id}' % { wordpress_id: self.member.api_id }).body unless self.new_record?
    end

    def update!
      res = conn.put('/api/user/%{wordpress_id}' % { wordpress_id: self.member.api_id }, fieldmap)
      update_member(res)
    end

    def create!
      res = conn.post '/api/user', fieldmap
      update_member(res)
    end

    def save!
      self.new_record? ? self.create! : self.update!
    end

    def destroy!
      res = conn.delete('/api/user/%{wordpress_id}' % { wordpress_id: self.member.api_id }, fieldmap)
      update_member(res)
    end

    def new_record?
      self.member.wordpress_id.nil?
    end

    def generate_admin_token!
      raise 'tbd'
    end

    def reset_password!
      raise 'tbd'
    end

    def resend_welcome_email!
      raise 'tbd'
    end

  private
    def conn
      self.member.club.wordpress
    end

    def update_member(res)
      data = if res.status == 200
        { 
          wordpress_id: res.body['uid'],
          last_synced_at: Time.now,
          last_sync_error: nil
        }
      else
        {
          last_sync_error: res.body
        }
      end
      ::Member.where(uuid: self.member.uuid).limit(1).update_all(data)
    end

    def fieldmap
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
