module SacMandrill
	module MemberExtensions

    def mandrill_configured?
      self.club.mandrill_configured?
    end

    def mandrill_member
      if self.club.marketing_tool_attributes and not self.club.marketing_tool_attributes["mandrill_api_key"].blank?
        @mandrill_member ||= if !self.mandrill_configured?
          nil
        else
          SacMandrill::MemberModel.new self
        end
      else
        Auditory.report_issue("Member:mandrill_member", 'Mandrill not configured correctly', { :club => self.club.inspect, :member => self.member })
        nil
      end
    end

	end
end