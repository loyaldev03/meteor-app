module Pardot
  class Prospect < Struct.new(:prospect)

    def save!
      unless self.prospect.email.include?('@noemail.com') # do not sync @noemail.com
        begin
          member = User.find_by_club_id_and_email(self.club.id, self.prospect.email)
          if member.nil?
            res = conn.prospects.save(CGI.escape(self.prospect.email), fieldmap)
            Pardot.logger.debug "Pardot answer: " + res.inspect
          end
        rescue Exception => e
          res = $!.to_s
          Pardot.logger.info "  => #{$!.to_s}"
        ensure
          res
        end
      end
    end

  private

    # will raise a Pardot::ResponseError if login fails
    # will raise a Pardot::NetError if the http call fails
    def conn
      c = self.prospect.club.pardot
      c.authenticate
      c
    end

    def fieldmap
      m = self.prospect

      map = {
        first_name: m.first_name,
        last_name: m.last_name,
        email: m.email,
        address_one: m.address,
        city: m.city,
        state: m.state,
        zip: m.zip,
        country: m.country,
        phone: m.full_phone_number,
        birth_date: m.birth_date,
        preferences: m.preferences,
        gender: m.gender,
        status: 'Prospect',
        club: m.club.name,
        client: m.club.partner.name,
        marketing_code: m.marketing_code.to_s.capitalize,
        mega_channel: m.mega_channel.to_s.capitalize,
        joint: (m.joint ? 1 : 0),
        fulfillment_code: m.fulfillment_code,
        campaign_medium_version: m.campaign_medium_version,
        campaign_medium: m.campaign_medium.to_s.capitalize,
        product_sku: m.product_sku,
        landing_url: m.landing_url,
        terms_of_membership_id: m.terms_of_membership_id
      }
      
      Pardot.logger.debug "Pardot JSON request: " + map.inspect
      map
    end
  end
end



