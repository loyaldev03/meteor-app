module Wordpress
  class Member < Struct.new(:user)
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
    #   [:member_id,      :profile,        :id],
    #   [:cc_month,       :profile_assoc,  :active_credit_card, :expire_month],
    #   [:cc_year,        :profile_assoc,  :active_credit_card, :expire_year],
    #   [:cc_number,      :profile_assoc,  :active_credit_card, :number]
    # ] 

    def get
      # conn.get('/api/user/%{wordpress_id}' % { wordpress_id: self.member.api_id }).body unless self.new_record?
    end

    def update!
      # Do nothing. 
      # query_string = { :sac_username => self.member.club.api_username, :sac_password => self.member.club.api_password, 
      #   :email => self.member.email, :username => self.member.email, :firstname => self.member.first_name, 
      #   :lastname => self.member.last_name, :action => 'update_user' }.collect {|key, value| "#{key}=#{value}"}.join('&')

      # res = conn.get '/api/?'+query_string
      # update_member(res)
    end

    def create!
      res = conn.get '/api/?' + query_string( { :email => self.user.email, :username => self.user.email, 
        :firstname => self.user.first_name, :lastname => self.user.last_name, :action => 'add_user' })
      update_member_api_id(res)
    end

    def save!
      self.new_record? ? self.create! : self.update!
    end

    def destroy!
      # res = conn.delete('/api/user/%{wordpress_id}' % { wordpress_id: self.member.api_id }, fieldmap)
    end

    def new_record?
      self.user.api_id.nil?
    end

    def reset_password!
      conn.get '/api/?' + query_string({ :user_id => self.user.api_id, :email => self.user.email, :action => 'reset_password' })
    end

    def resend_welcome_email!
      conn.get '/api/?' + query_string({ :user_id => self.user.api_id, :email => self.user.email, :action => 'resend_welcome_email' })
    end

  private
    def query_string(hash)
      { :sac_username => self.user.club.api_username, :sac_password => self.user.club.api_password }.merge!(hash).collect {|key, value| "#{key}=#{value}"}.join('&')
    end

    def conn
      self.user.club.wordpress
    end

    def update_member(res)
      data = if res.status == 200
        { 
          name: res.body['name'],
          email: res.body['email'],
          address: res.body['address'],
          first_name: res.body['firstname'],
          last_name: res.body['lastname'],
          city: res.body['city'],
          state: res.body['state'],
          zip: res.body['zip'],
          country: res.body['country'],
          phone_number: res.body['phone_number'],
          last_synced_at: Time.now,
          last_sync_error: nil
        }
      else
        {
          last_sync_error: res.body
        }
      end
      ::User.where(id: self.user.id).limit(1).update_all(data)
    end


    def update_member_api_id(res)
      data = if res.status == 200
        { 
          api_id: res.body['user_id'],
          last_synced_at: Time.now,
          last_sync_error: nil
        }
      else
        {
          last_sync_error: res.body
        }
      end
      ::User.where(id: self.user.id).limit(1).update_all(data)
    end

  end
end
