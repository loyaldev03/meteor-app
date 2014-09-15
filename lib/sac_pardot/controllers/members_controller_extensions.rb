module Pardot
  module MembersControllerExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def pardot_sync
        am = @current_user.pardot_member
        if am
          am.save!
          if @current_user.marketing_client_last_sync_error_at
            message = "Synchronization to pardot failed: #{@current_user.marketing_client_last_sync_error_at}"
          else
            message = "Member synchronized to pardot"
          end
          Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.user_manually_synced_to_pardot)
          redirect_to show_user_path, notice: message    
        end
      rescue
        flash[:error] = t('error_messages.airbrake_error_message')
        Auditory.report_issue("Member:pardot_sync", "Error on members#pardot_sync: #{$!}", { :member => @current_user.inspect })
        redirect_to show_user_path
      end
    end
  end
end