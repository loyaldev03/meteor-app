#!/bin/ruby

require_relative 'import_models'


def add_operation(operation_date, object, description, operation_type, created_at, updated_at, author = 999)
  # TODO: levantamos los Agents?
  #current_agent = Agent.find_by_email('batch@xagax.com') if author == 999
  o = PhoenixOperation.new :operation_date => operation_date, :description => description, :operation_type => operation_type
  o.created_by_id = CREATED_BY
  o.created_at = created_at
  if object.nil?
    o.resource_type = nil
    # o.resource_id = 0
  end
  o.updated_at = updated_at
  o.member_id = @member.uuid
  o.save!
end

def load_refunds
  # 'void'
end

def load_enrollment_transactions
  BillingEnrollmentAuthorizationResponse.find_in_batches do |group|
    group.each do |response|
      tz = Time.now
      begin
        @log.info "  * processing Enrollment Auth response ##{response.id}"
        if response.authorization.nil?
          @log.info "  * Enrollment Authorization id not found for Auth response ##{response.id} member id ##{response.authorization_id}"
        else
          @member = response.member
          if @member.nil?
            @log.info "  * Member id not found for Auth response ##{response.id} member id ##{response.authorization.member_id}"
          else
            transaction = PhoenixTransaction.new
            transaction.member_id = @member.uuid
            transaction.terms_of_membership_id = get_terms_of_membership_id(response.authorization.campaign_id)
            transaction.set_payment_gateway_configuration
            transaction.gateway = 'litle'
            transaction.recurrent = false
            transaction.transaction_type = 'authorization_capture'
            transaction.invoice_number = "#{response.created_at.to_date}-#{response.authorization.member_id}"
            transaction.amount = response.amount
            transaction.response = { :authorization => response.message, :capture => (response.capture_response.message rescue nil) }
            transaction.response_code = response.code
            if response.capture and response.capture_response and response.capture_response.code
              transaction.response_code = response.capture_response.code
            end
            transaction.response_result = transaction.response
            if response.code.to_i == 0
              transaction.response_transaction_id = response.authorization.litleTxnId
            end
            transaction.response_auth_code = response.authorization.auth_code
            if response.capture and response.capture.auth_code
              transaction.response_auth_code = response.capture.auth_code
            end
            transaction.created_at = response.created_at
            transaction.updated_at = response.updated_at
            transaction.refunded_amount = 0
            transaction.save!

            if transaction.response_code.to_i == 0 and (response.authorization.captured == 1 || response.authorization.authorized == 1)
              add_operation(transaction.created_at, transaction, 
                            "Member enrolled successfully $#{transaction.amount} on TOM(#{transaction.terms_of_membership_id}) -#{get_terms_of_membership_name(transaction.terms_of_membership_id)}-",
                            Settings.operation_types.membership_billing, transaction.created_at, transaction.updated_at)
            else
              # Today we dont save failed enrollments operations
              #add_operation(transaction.created_at, transaction, 
              #              "Soft Declined: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}",
              #              Settings.operation_types.membership_billing_soft_decline, transaction.created_at, transaction.updated_at)
            end
            response.destroy
          end
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
      @log.info "    ... took #{Time.now - tz} for Enrollment Auth response ##{response.id}"
    end
  end
end


def load_membership_transactions
  BillingMembershipAuthorizationResponse.find_in_batches do |group|
    group.each do |response|
      tz = Time.now
      begin
        @log.info "  * processing Membership Auth response ##{response.id}"
        if response.authorization.nil?
          @log.info "  * Membership Authorization id not found for Auth response ##{response.id} member id ##{response.authorization_id}"
        else
          @member = response.member
          if @member.nil? or response.capture.nil?
            @log.info "  * Member id not found for Auth response ##{response.id} member id ##{response.authorization.member_id}"
          else
            transaction = PhoenixTransaction.new
            transaction.member_id = @member.uuid
            transaction.terms_of_membership_id = get_terms_of_membership_id(response.authorization.campaign_id)
            transaction.set_payment_gateway_configuration
            transaction.gateway = 'litle'
            transaction.recurrent = false
            transaction.transaction_type = 'authorization_capture'
            transaction.invoice_number = "#{response.created_at.to_date}-#{response.authorization.member_id}"
            transaction.amount = response.amount
            transaction.response = { :authorization => response.message, :capture => (response.capture_response.message rescue nil) }
            transaction.response_code = response.code
            if response.capture and response.capture_response
              transaction.response_code = response.capture_response.code
            end
            transaction.response_result = transaction.response
            if response.code.to_i == 0
              transaction.response_transaction_id = response.authorization.litleTxnId
            end
            transaction.response_auth_code = (response.capture.auth_code || response.authorization.auth_code)
            transaction.created_at = response.created_at
            transaction.updated_at = response.updated_at
            transaction.refunded_amount = 0
            transaction.save!
            if transaction.response_code.to_i == 0 and (response.authorization.captured == 1 || response.authorization.authorized == 1)
              add_operation(transaction.created_at, transaction, 
                            "Member billed successfully $#{transaction.amount} Transaction id: #{transaction.id}", 
                            Settings.operation_types.membership_billing, transaction.created_at, transaction.updated_at)
            elsif [301,327,304,303].include?(transaction.response_code.to_i)
              add_operation(transaction.created_at, transaction, 
                            "Hard Declined: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}", 
                            Settings.operation_types.membership_billing_hard_decline, transaction.created_at, transaction.updated_at)
            else
              add_operation(transaction.created_at, transaction, 
                            "Soft Declined: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}",
                            Settings.operation_types.membership_billing_soft_decline, transaction.created_at, transaction.updated_at)
            end
            response.destroy
          end
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
      @log.info "    ... took #{Time.now - tz} for Membership Auth response ##{response.id}"
    end
  end
end

def set_last_billing_date_on_credit_card
  PhoenixMember.find_in_batches do |group|
    group.each do |member|
      tz = Time.now
      begin
        @log.info "  * processing Membership Auth response ##{response.id}"
        transaction = PhoenixTransaction.find_by_member_id member.uuid, :order => "created_at DESC"
        cc = member.active_credit_card
        cc.update_attribute :last_successful_bill_date, transaction.created_at
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
      @log.info "    ... took #{Time.now - tz} for Membership Auth response ##{response.id}"
    end
  end
end


#load_enrollment_transactions
load_membership_transactions
set_last_billing_date_on_credit_card
load_refunds

