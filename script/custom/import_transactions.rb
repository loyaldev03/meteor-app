#!/bin/ruby

require './import_models'

@log = Logger.new('log/import_transactions.log', 10, 1024000)
ActiveRecord::Base.logger = @log

def load_refunds
  BillingChargeback.where(" imported_at IS NULL and phoenix_amount IS NOT NULL "+
    (USE_MEMBER_LIST ? " and member_id IN (#{PhoenixMember.find_all_by_club_id(CLUB).map(&:visible_id).join(',')}) " : "")
  ).find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |refund|
      @member = PhoenixMember.find_by_club_id_and_visible_id(CLUB, refund.member_id)
      unless @member.nil?
        tz = Time.now.utc
        @log.info "  * processing Chargeback ##{refund.id}"
        begin
          # TODO: update refunded $$ on transactions
          transaction = PhoenixTransaction.new
          transaction.member_id = @member.uuid
          transaction.terms_of_membership_id = @member.terms_of_membership_id
          transaction.gateway = refund.phoenix_gateway
          transaction.set_payment_gateway_configuration(transaction.gateway)
          transaction.recurrent = false
          transaction.transaction_type = "credit" 
          transaction.invoice_number = @member.visible_id
          transaction.amount = refund.phoenix_amount
          transaction.response = refund.result
          transaction.response_code = (refund.result == "Success" ? "000" : "999")
          transaction.response_result = refund.result
          transaction.response_transaction_id = refund.litle_txn_id
          transaction.created_at = refund.created_at
          transaction.updated_at = refund.updated_at
          transaction.save!

          if refund.result == "Success"
            add_operation(transaction.created_at, 'Transaction', transaction.id, "Refund success $#{transaction.amount}",
                              Settings.operation_types.credit, transaction.created_at, transaction.updated_at)
          else
            add_operation(transaction.created_at, 'Transaction', transaction.id, "Refund $#{transaction.amount} error: #{refund.result}",
                              Settings.operation_types.credit_error, transaction.created_at, transaction.updated_at)
          end
          refund.update_attribute :imported_at, Time.now.utc
          print "."
        rescue Exception => e
          @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          exit
        end
        @log.info "    ... took #{Time.now.utc - tz} for Chargeback ##{refund.id}"
      end
    end
  end
end

def load_enrollment_transactions
  BillingEnrollmentAuthorizationResponse.
  joins(' JOIN enrollment_authorizations ON enrollment_authorizations.id = enrollment_auth_responses.authorization_id ').
  where(" enrollment_authorizations.campaign_id IS NOT NULL and imported_at IS NULL and phoenix_amount IS NOT NULL " +
    (USE_MEMBER_LIST ? " and member_id IN (#{PhoenixMember.find_all_by_club_id(CLUB).map(&:visible_id).join(',')}) " : "")
  ).find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |response|
      authorization = response.authorization
      if not authorization.nil? 
        begin
          tz = Time.now.utc
          @log.info "  * processing Enrollment Auth response ##{response.id}"
          @member = response.member
          unless @member.nil?
            transaction = PhoenixTransaction.new
            transaction.member_id = @member.uuid
            get_campaign_and_tom_id(authorization.campaign_id)
            transaction.terms_of_membership_id = @tom_id
            next if transaction.terms_of_membership_id.nil?
            transaction.gateway = response.phoenix_gateway
            transaction.set_payment_gateway_configuration(transaction.gateway)
            transaction.recurrent = false
            transaction.transaction_type = 'authorization_capture'
            transaction.invoice_number = response.invoice_number(authorization)
            transaction.amount = response.amount
            transaction.response = { :authorization => response.message }
            transaction.response_code = response.code
            transaction.response_result = transaction.response
            if response.code.to_i == 0
              transaction.response_transaction_id = authorization.litleTxnId
            end
            transaction.response_auth_code = authorization.auth_code
            transaction.created_at = response.created_at
            transaction.updated_at = response.updated_at
            transaction.refunded_amount = 0
            transaction.save!

            if transaction.response_code.to_i == 0 and (authorization.captured == 1 || authorization.authorized == 1)
              set_last_billing_date_on_credit_card(@member, transaction.created_at)
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Member enrolled successfully $#{transaction.amount} on TOM(#{transaction.terms_of_membership_id}) -#{get_terms_of_membership_name(transaction.terms_of_membership_id)}-",
                            Settings.operation_types.membership_billing, transaction.created_at, transaction.updated_at)
            end
            # This find is need it because find_in_batches has a join and record is readonly
            r = BillingEnrollmentAuthorizationResponse.find response.id
            r.update_attribute :imported_at, Time.now.utc
            print "."
          end
        rescue Exception => e
          @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          exit
        end
        @log.info "    ... took #{Time.now.utc - tz} for Enrollment Auth response ##{response.id}"
      end
    end
  end
end


def load_membership_transactions
  BillingMembershipAuthorizationResponse.
  joins(' JOIN membership_authorizations ON membership_authorizations.id = membership_auth_responses.authorization_id ').
  where(" membership_authorizations.campaign_id IS NOT NULL and  imported_at IS NULL and phoenix_amount IS NOT NULL " +
    (USE_MEMBER_LIST ? " and member_id IN (#{PhoenixMember.find_all_by_club_id(CLUB, :limit => 400).map(&:visible_id).join(',')}) " : "")
  ).find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |response|
      authorization = response.authorization
      unless authorization.nil?
        begin
          tz = Time.now.utc
          @member = response.member
          unless @member.nil?
            @log.info "  * processing Membership Auth response ##{response.id}"
            transaction = PhoenixTransaction.new
            transaction.member_id = @member.uuid
            get_campaign_and_tom_id(authorization.campaign_id)
            transaction.terms_of_membership_id = @tom_id
            next if transaction.terms_of_membership_id.nil?
            transaction.gateway = response.phoenix_gateway
            transaction.set_payment_gateway_configuration(transaction.gateway)
            transaction.recurrent = false
            transaction.transaction_type = 'authorization_capture'
            transaction.invoice_number = response.invoice_number(authorization)
            transaction.amount = response.amount
            transaction.response = { :authorization => response.message }
            transaction.response_code = response.code
            transaction.response_result = transaction.response
            if response.code.to_i == 0
              transaction.response_transaction_id = authorization.litleTxnId
            end
            transaction.response_auth_code = authorization.auth_code
            transaction.created_at = response.created_at
            transaction.updated_at = response.updated_at
            transaction.refunded_amount = 0
            transaction.save!
            if transaction.response_code.to_i == 0 and (authorization.captured == 1 || authorization.authorized == 1)
              set_last_billing_date_on_credit_card(@member, transaction.created_at)
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Member billed successfully $#{transaction.amount} Transaction id: #{transaction.id}", 
                            Settings.operation_types.membership_billing, transaction.created_at, transaction.updated_at)
            elsif [301,327,304,303].include?(transaction.response_code.to_i)
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Hard Declined: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}", 
                            Settings.operation_types.membership_billing_hard_decline, transaction.created_at, transaction.updated_at)
            else
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Soft Declined: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}",
                            Settings.operation_types.membership_billing_soft_decline, transaction.created_at, transaction.updated_at)
            end
            # This find is need it because find_in_batches has a join and record is readonly
            r = BillingMembershipAuthorizationResponse.find response.id
            r.update_attribute :imported_at, Time.now.utc
            print "."
          end
        rescue Exception => e
          @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          exit
        end
        @log.info "    ... took #{Time.now.utc - tz} for Membership Auth response ##{response.id}"
      end
    end
  end
end




load_refunds
load_enrollment_transactions
load_membership_transactions


