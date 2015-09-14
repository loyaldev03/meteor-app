module SacMailchimp
  module MembersControllerExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def mailchimp_sync
        am = @current_user.mailchimp_member
        if am
          am.save!
          if @current_user.marketing_client_last_sync_error_at
            message = "Synchronization to mailchimp failed: #{@current_user.marketing_client_last_sync_error_at}"
          else
            message = "Member synchronized to mailchimp"
          end
          Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.user_manually_synced_to_mailchimp)
          redirect_to show_user_path, notice: message    
        end
      rescue Exception => e
        message = e.to_s.include?("Gibbon::MailChimpError") ? t('error_messages.airbrake_error_message_for_mkt_sync', :response => e) : t('error_messages.airbrake_error_message')
        flash[:error] = message
        Auditory.report_issue("Member:mailchimp_sync", e, { :member => @current_user.inspect }) unless SacMailchimp::NO_REPORTABLE_ERRORS.include? e.code.to_s
        redirect_to show_user_path
      end
    end
  end
end