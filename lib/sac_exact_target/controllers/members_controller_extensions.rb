module SacExactTarget
  module MembersControllerExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def exact_target_sync
        am = @current_user.exact_target_member
        if am
          am.save!
          if @current_user.marketing_client_last_sync_error_at
            message = "Synchronization to exact_target failed: #{@current_user.marketing_client_last_sync_error_at}"
          else
            message = "Member synchronized to exact_target"
          end
          Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.user_manually_synced_to_exact_target)
          redirect_to show_user_path, notice: message    
        end
      rescue Exception => e
        flash[:error] = t('error_messages.airbrake_error_message_for_mkt_sync', :response => e)
        SacExactTarget::report_error("Member:exact_target_sync", e, @current_user)
        redirect_to show_user_path
      end
    end
  end
end