module SacMandrill
	module MemberExtensions

    def mandrill_configured?
      self.club.mandrill_configured?
    end

    def mandrill_member
      return @mandrill_member unless @mandrill_member.nil?
      if self.club.mandrill_configured?
        @mandrill_member ||= if !self.mandrill_configured?
          false
        else
          SacMandrill::MemberModel.new self
        end
      else
        Auditory.report_issue('Member:mandrill_member : Mandrill not configured correctly', nil, { :club => self.club.id, :member => self.id })
        false
      end
    end

	end
end