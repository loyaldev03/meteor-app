module SacExactTarget
  module MembersControllerExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def exact_target_sync
        am = @current_member.exact_target_member
        if am
          am.save!
          if @current_member.exact_target_last_sync_error_at
            message = "Synchronization to exact_target failed: #{@current_member.exact_target_last_sync_error_at}"
          else
            message = "Member synchronized to exact_target"
          end
          Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.member_manually_synced_to_exact_target)
          redirect_to show_member_path, notice: message    
        end
      rescue
        flash[:error] = t('error_messages.airbrake_error_message')
        Auditory.report_issue("Member:exact_target_sync", "Error on members#exact_target_sync: #{$!}", { :member => @current_member.inspect })
        redirect_to show_member_path
      end
    end
  end
end