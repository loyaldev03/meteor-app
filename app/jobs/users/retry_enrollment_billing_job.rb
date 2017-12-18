module Users
  class RetryEnrollmentBillingJob < ActiveJob::Base
    queue_as :enrollment_delayed_billing
    attr :user
    
    def downgrade_membership(original_terms_of_membership, reason)
      tom_to_downgrade = @user.club.terms_of_memberships.find_by name: 'Limited access members'
      @user.save_the_sale(tom_to_downgrade.id) if tom_to_downgrade

      notify_agent(original_terms_of_membership, reason)
    end
    
    def notify_agent(terms_of_membership, reason)
      error_message = "Phoenix was not able to bill the enrollment amount during enrollment due to cut-off process, and failed to do it later as well."
      Auditory.report_issue("Enrollnment Billing Error", error_message, { 'User ID': @user.id, 'Subscription Plan': "(ID##{terms_of_membership.id})#{terms_of_membership.name}",'Reason why user was not billed': reason }, false, Settings.retry_enrollment_process_fail_assignee)
    end
    
    def perform(user_id, retry_count = 0)
      @user               = User.find user_id
      membership          = @user.current_membership
      terms_of_membership = membership.terms_of_membership
      operation_type      = membership.parent_membership_id.nil? ? Settings.operation_types.enrollment_billing : Settings.operation_types.recovery
      
      begin
        trans = Transaction.obtain_transaction_by_gateway!(terms_of_membership.payment_gateway_configuration.gateway)
        trans.transaction_type = "sale"
        trans.prepare(@user, @user.active_credit_card, membership.campaign.enrollment_price, terms_of_membership.payment_gateway_configuration, terms_of_membership.id, nil, operation_type)
        trans.process
        if trans.success
          Users::PostEnrollmentTasks.perform_later(@user.id, false)
        elsif trans.failure_due_to_cut_off? and retry_count < 5   
          Users::RetryEnrollmentBillingJob.set(wait: 10.minutes).perform_later(@user.id, retry_count+1)
        else
          reason = retry_count < 5 ? trans.response_result : 'Reached max amount of retries (6).'
          downgrade_membership(terms_of_membership, reason)
        end
      rescue
        downgrade_membership(terms_of_membership, $!)
      end
    end
  end 
end