#!/bin/ruby

require './import_models'

@log = Logger.new('log/import_transactions.log', 10, 1024000)
ActiveRecord::Base.logger = @log

def process_chargeback(refund, terms_of_membership_id = nil)
  @member = PhoenixMember.find_by_club_id_and_id(CLUB, refund.member_id)
  unless @member.nil?
    tz = Time.now.utc
    @log.info "  * processing Chargeback ##{refund.id}"
    begin
      transaction = PhoenixTransaction.new
      transaction.member_id = @member.id
      if terms_of_membership_id.nil?
        transaction.terms_of_membership_id = @member.terms_of_membership_id
      else
        transaction.terms_of_membership_id = terms_of_membership_id
      end
      transaction.gateway = refund.phoenix_gateway
      transaction.set_payment_gateway_configuration(transaction.gateway)
      transaction.recurrent = false
      transaction.transaction_type = "credit" 
      transaction.invoice_number = @member.id
      transaction.amount = refund.phoenix_amount
      transaction.response = refund.result
      transaction.response_code = (refund.result == "Success" ? "000" : "999")
      transaction.success = (transaction.response_code == '000')
      transaction.response_result = refund.result
      transaction.response_transaction_id = refund.litle_txn_id
      transaction.membership_id = @member.current_membership_id
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

      r = BillingChargeback.find refund.id
      r.update_attribute :imported_at, Time.now.utc
      print "."
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      exit
    end
    @log.info "    ... took #{Time.now.utc - tz} for Chargeback ##{refund.id}"
  end
end

def load_refunds_controlled
  BillingChargeback.joins(' JOIN members ON chargebacks.member_id = members.id ').
	where(" chargebacks.imported_at IS NULL and chargebacks.phoenix_amount IS NOT NULL and chargebacks.phoenix_amount > 0.0 " +
                " and members.imported_at IS NOT NULL and result = 'Success' and chargebacks.campaign_id IS NOT NULL and chargebacks.campaign_id != 0" +
		" and chargebacks.reason not like '%Uncontroled%' ").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |refund|
      begin
        current_t = if [ 'Membership Capture', 'Membership Capture MeS', 'MembershipCapture', 'Webservice Capture MES' ].include?(refund.reason)
  	  BillingMembershipAuthorizationResponse.
		  joins(' JOIN membership_authorizations ON membership_authorizations.id = membership_auth_responses.authorization_id '+
			' JOIN membership_captures ON membership_captures.litleTxnId = membership_authorizations.litleTxnId '+
			' JOIN members ON membership_authorizations.member_id = members.id ').
		  where(" membership_authorizations.campaign_id != 0 and membership_authorizations.campaign_id IS NOT NULL and  membership_auth_responses.imported_at IS NOT NULL " + 
			" AND membership_auth_responses.phoenix_amount IS NOT NULL and membership_auth_responses.phoenix_amount != 0.0 " +
			" AND members.imported_at IS NOT NULL AND membership_captures.id = #{refund.capture_id}").first
        elsif [ 'Enrollment Capture', 'Enrollment Capture MeS', 'EnrollmentCapture' ].include?(refund.reason)
  	  BillingEnrollmentAuthorizationResponse.
            joins(' JOIN enrollment_authorizations ON enrollment_authorizations.id = enrollment_auth_responses.authorization_id ' + 
		' JOIN enrollment_captures ON enrollment_captures.litleTxnId = enrollment_authorizations.litleTxnId '+
                ' JOIN members ON enrollment_authorizations.member_id = members.id ').
            where(" enrollment_authorizations.campaign_id != 0 and enrollment_authorizations.campaign_id IS NOT NULL and enrollment_auth_responses.imported_at IS NOT NULL " + 
                " and enrollment_auth_responses.phoenix_amount IS NOT NULL and enrollment_auth_responses.phoenix_amount != 0.0 " + 
                " and enrollment_auth_responses.message not like 'Failed%' " + # These transacciones have code == 0 :(
                " and members.imported_at IS NOT NULL AND enrollment_captures.id = #{refund.capture_id}").first
        end

	      if current_t.nil?
	      puts "xxxxxxxxxxxxxxxxxx"
	      next
	      else
	      puts "current t found"
	      end

        if current_t.gateway == 'litle'
          transaction_type = 'authorization_capture'
        else
          transaction_type = 'sale'
        end

        authorization = current_t.authorization
        next if authorization.nil?
	puts "current auth found"
        @member = current_t.member(authorization)


        phoenix_t = PhoenixTransaction.find_by_member_id_and_created_at_and_updated_at_and_response_code @member.id, current_t.created_at, current_t.updated_at, '000'
        next if phoenix_t.nil?
	puts "phoenix t found"
        
        process_chargeback(refund, phoenix_t.terms_of_membership_id)
        if refund.result == 'Success'
          phoenix_t.refunded_amount += refund.phoenix_amount
          phoenix_t.save!
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
    end
  end
end

def load_refunds_uncontrolled
  BillingChargeback.joins(' JOIN members ON chargebacks.member_id = members.id ').
	where(" chargebacks.imported_at IS NULL and chargebacks.phoenix_amount IS NOT NULL and chargebacks.phoenix_amount > 0.0 " +
                " and members.imported_at IS NOT NULL and result = 'Success'" +
		" and chargebacks.reason like '%Uncontroled%' ").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |refund|
      process_chargeback(refund)
    end
  end
end

def process_chargeback_from_transaction(phoenix_t, current_t, type)
  refund = nil
  case type 
    when 'membership'
      reasons = [ 'Membership Capture', 'Membership Capture MeS', 'MembershipCapture', 'Webservice Capture MES' ]
      refunds = BillingChargeback.joins(' join membership_captures on chargebacks.capture_id = membership_captures.id ' +
            ' join membership_authorizations on membership_captures.litleTxnId = membership_authorizations.litleTxnId ').
          where([ " chargebacks.imported_at IS NULL and chargebacks.phoenix_amount IS NOT NULL AND membership_authorizations.campaign_id IS NOT NULL " +
            " and chargebacks.reason IN (?) and membership_authorizations.litleTxnId = ? ", 
            reasons, current_t.litleTxnId ]).all
    when 'enrollment'
      reasons = [ 'Enrollment Capture', 'Enrollment Capture MeS', 'EnrollmentCapture' ]
      refunds = BillingChargeback.joins(' join enrollment_captures on chargebacks.capture_id = enrollment_captures.id ' +
            ' join enrollment_authorizations on enrollment_captures.litleTxnId = enrollment_authorizations.litleTxnId ').
          where([ " chargebacks.imported_at IS NULL and chargebacks.phoenix_amount IS NOT NULL AND enrollment_authorizations.campaign_id IS NOT NULL " +
            " and chargebacks.reason IN (?) and enrollment_authorizations.litleTxnId = ? ", 
            reasons, current_t.litleTxnId ]).all
  end
  refunds.each do |refund|
    process_chargeback(refund, phoenix_t.terms_of_membership_id)
    if refund.result == 'Success'
      phoenix_t.refunded_amount += refund.phoenix_amount
      phoenix_t.save!
    end
  end

rescue Exception => e
  @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  exit
end


def load_enrollment_transactions
  BillingEnrollmentAuthorizationResponse.
  joins(' JOIN enrollment_authorizations ON enrollment_authorizations.id = enrollment_auth_responses.authorization_id ' + 
	' JOIN members ON enrollment_authorizations.member_id = members.id ').
  where(" enrollment_authorizations.campaign_id != 0 and enrollment_authorizations.campaign_id IS NOT NULL and enrollment_auth_responses.imported_at IS NULL " + 
	" and enrollment_auth_responses.phoenix_amount IS NOT NULL and enrollment_auth_responses.phoenix_amount != 0.0 " + 
  " and enrollment_auth_responses.message not like 'Failed%' " + # These transacciones have code == 0 :(
  " and members.imported_at IS NOT NULL " +
  "").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |response|
      authorization = response.authorization
      if not authorization.nil? 
        begin
          tz = Time.now.utc
          @log.info "  * processing Enrollment Auth response ##{response.id}"
          @member = response.member(authorization)
          unless @member.nil?
            transaction = PhoenixTransaction.new
            transaction.member_id = @member.id
            get_campaign_and_tom_id(authorization.campaign_id)
            transaction.terms_of_membership_id = @tom_id
            next if transaction.terms_of_membership_id.nil?
            transaction.gateway = response.phoenix_gateway
            transaction.set_payment_gateway_configuration(transaction.gateway)
            transaction.recurrent = false
            if transaction.gateway == 'litle'
              transaction.transaction_type = 'authorization_capture'
            else
              transaction.transaction_type = 'sale'
            end
            transaction.invoice_number = response.invoice_number(authorization)
            transaction.amount = response.amount
            transaction.response = response.message
            transaction.response_code = "%03d" % response.code.to_i
            transaction.response_result = transaction.response
            if response.code.to_i == 0
              transaction.response_transaction_id = authorization.litleTxnId
            end
            transaction.success = (transaction.response_code == '000')
            transaction.response_auth_code = authorization.auth_code
	         transaction.membership_id = @member.current_membership_id
            transaction.created_at = response.created_at
            transaction.updated_at = response.updated_at
            transaction.refunded_amount = 0
            transaction.save!

            if transaction.response_code.to_i == 0 and (authorization.captured == 1 || authorization.authorized == 1)
              set_last_billing_date_on_credit_card(@member, transaction.created_at)
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Member enrolled successfully $#{transaction.amount} on TOM(#{transaction.terms_of_membership_id}) -#{get_terms_of_membership_name(transaction.terms_of_membership_id)}-",
                            Settings.operation_types.enrollment_billing, transaction.created_at, transaction.updated_at)
	            process_chargeback_from_transaction(transaction, authorization, 'enrollment')
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
  joins(' JOIN membership_authorizations ON membership_authorizations.id = membership_auth_responses.authorization_id '+
	' JOIN members ON membership_authorizations.member_id = members.id ').
  where(" membership_authorizations.campaign_id != 0 and membership_authorizations.campaign_id IS NOT NULL and  membership_auth_responses.imported_at IS NULL " + 
	" AND membership_auth_responses.phoenix_amount IS NOT NULL and membership_auth_responses.phoenix_amount != 0.0 " +
	" AND members.imported_at IS NOT NULL "
  ).find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |response|
      authorization = response.authorization
      unless authorization.nil?
        begin
          tz = Time.now.utc
          @member = response.member(authorization)
          unless @member.nil?
            @log.info "  * processing Membership Auth response ##{response.id}"
            transaction = PhoenixTransaction.new
            transaction.member_id = @member.id
            get_campaign_and_tom_id(authorization.campaign_id)
            transaction.terms_of_membership_id = @tom_id
            next if transaction.terms_of_membership_id.nil?
            transaction.gateway = response.phoenix_gateway
            transaction.set_payment_gateway_configuration(transaction.gateway)
            transaction.recurrent = false
            if transaction.gateway == 'litle'
              transaction.transaction_type = 'authorization_capture'
            else
              transaction.transaction_type = 'sale'
            end
            transaction.invoice_number = response.invoice_number(authorization)
            transaction.amount = response.amount
            transaction.response = response.message
            transaction.response_code = "%03d" % response.code.to_i
            if (response.message.include?('Authorized') || response.message == 'Membership success') and transaction.response_code.to_i == 0 and (authorization.captured == 1 || authorization.authorized == 1)
              transaction.response_code = "%03d" % 0
            elsif transaction.response_code == "000"
              transaction.response_code = "990" # some soft declines have 000 errors code, I have to fix them :(
            end
            
            transaction.response_result = transaction.response
            if response.code.to_i == 0
              transaction.response_transaction_id = authorization.litleTxnId
            end
            transaction.response_auth_code = authorization.auth_code
            transaction.success = (transaction.response_code == '000')
	           transaction.membership_id = @member.current_membership_id
            transaction.created_at = response.created_at
            transaction.updated_at = response.updated_at
            transaction.refunded_amount = 0
            transaction.save!
            if (response.message.include?('Authorized') || response.message == 'Membership success') and transaction.response_code.to_i == 0 and (authorization.captured == 1 || authorization.authorized == 1)
              set_last_billing_date_on_credit_card(@member, transaction.created_at)
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Member billed successfully $#{transaction.amount} Transaction id: #{transaction.id}", 
                            Settings.operation_types.membership_billing, transaction.created_at, transaction.updated_at)
	            process_chargeback_from_transaction(transaction, authorization, 'membership')
            elsif [301,327,304,303].include?(transaction.response_code.to_i)
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Hard Declined: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}", 
                            Settings.operation_types.membership_billing_hard_decline, transaction.created_at, transaction.updated_at)
            else
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Soft Declined: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}",
                            Settings.operation_types.membership_billing_soft_decline, transaction.created_at, transaction.updated_at)
            end
            # This find is needed because find_in_batches has a join and record is readonly
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



#load_enrollment_transactions
#load_membership_transactions
#load_refunds_uncontrolled
load_refunds_controlled



