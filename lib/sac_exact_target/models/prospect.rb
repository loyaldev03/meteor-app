module SacExactTarget
  class Prospect < Struct.new(:prospect)

    def create!
      unless self.prospect.email.include?('@noemail.com') # do not sync @noemail.com
        begin
          member = Member.find_by_club_id_and_email(self.club.id, self.prospect.email)
          if member.nil?
            res = conn.prospects.save(CGI.escape(self.prospect.email), fieldmap)
            SacExactTarget.logger.debug "Pardot answer: " + res.inspect
          end
        rescue Exception => e
          res = $!.to_s
          SacExactTarget.logger.info "  => #{$!.to_s}"
        ensure
          res
        end
      end
    end

  private

    # will raise a Pardot::ResponseError if login fails
    # will raise a Pardot::NetError if the http call fails
    def conn

    end

    def fieldmap
      
      SacExactTarget.logger.debug "Pardot JSON request: " + map.inspect
      map
    end
  end
end



