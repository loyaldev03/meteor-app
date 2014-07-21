module SacMailchimp
  module MembersControllerExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def mailchimp_sync
        am = @current_member.mailchimp_member
        if am
          am.save!
          if @current_member.marketing_client_last_sync_error_at
            message = "Synchronization to mailchimp failed: #{@current_member.marketing_client_last_sync_error_at}"
          else
            message = "Member synchronized to mailchimp"
          end
          Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.member_manually_synced_to_mailchimp)
          redirect_to show_member_path, notice: message    
        end
      rescue
        flash[:error] = t('error_messages.airbrake_error_message')
        Auditory.report_issue("Member:mailchimp_sync", "Error on members#mailchimp_sync: #{$!}", { :member => @current_member.inspect })
        redirect_to show_member_path
      end
    end
  end
end