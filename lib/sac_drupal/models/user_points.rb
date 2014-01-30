module Drupal
  class UserPoints < Struct.new(:member)

    def get
      res = conn.get('/api/userpoints/%{drupal_id}' % { drupal_id: self.member.api_id }).body
    rescue Faraday::Error::ParsingError # Drupal sends invalid application/json when something goes wrong
      Drupal.logger.info "  => #{$!.to_s}"
    ensure
      res
    end

    def create!(options = {})
      res = conn.post '/api/userpoints/add', fieldmap(options)
      update_member(res)
    end

  private
    def conn
      self.member.club.drupal
    end

    def update_member(res)
      if res
        data = if res.status == 200
          { 
            last_synced_at: Time.now,
            last_sync_error: nil,
            last_sync_error_at: nil,
            sync_status: "synced",
            club_cash_amount: res.body['total_points']
          }
        else
          {
            last_sync_error: res.body.class == Hash ? res.body[:message] : res.body,
            last_sync_error_at: Time.now,
            sync_status: "with_error"
          }
        end
        ::Member.where(id: self.member.id).limit(1).update_all(data)
        self.member.reload rescue self.member
      end
    end

    def fieldmap(options)
      {
        uid: member.api_id,
        points: options[:amount].to_f*100,
        operation: "Add",
        description: options[:description],
        entity_type: "",
        entity_id: "" 
      }
    end
  end
end



