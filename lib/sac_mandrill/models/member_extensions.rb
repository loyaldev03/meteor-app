module SacMailchimp
	module MemberExtensions

    def mandrill_sync?
      self.club.mandrill_sync?
    end

    def mandrill_member
      if self.club.marketing_tool_attributes and not self.club.marketing_tool_attributes["mandrill_api_key"].blank?
        SacMailchimp.config_integration(self.club.marketing_tool_attributes["mandrill_api_key"])
        @mailchimp_member ||= if !self.mailchimp_sync?
          nil
        else
          SacMandrill::MemberModel.new self
        end
      else
        Auditory.report_issue("Member:mailchimp_member", 'Mandrill not configured correctly', { :club => self.club.inspect })
        nil
      end
    end

	end
end