module Pardot
  module MembersControllerExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def pardot_sync
        am = @current_member.pardot_member
        if am
          am.save!
          if @current_member.marketing_client_last_sync_error_at
            message = "Synchronization to pardot failed: #{@current_member.marketing_client_last_sync_error_at}"
          else
            message = "Member synchronized to pardot"
          end
          Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.member_manually_synced_to_pardot)
          redirect_to show_member_path, notice: message    
        end
      rescue
        flash[:error] = t('error_messages.airbrake_error_message')
        Auditory.report_issue("Member:pardot_sync", "Error on members#pardot_sync: #{$!}", { :member => @current_member.inspect })
        redirect_to show_member_path
      end
    end
  end
end