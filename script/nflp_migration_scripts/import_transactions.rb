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
      transaction.response = refund.message
      transaction.response_code = (refund.message == "Success" ? "000" : "999")
      transaction.success = (transaction.response_code == '000')
      transaction.response_result = refund.message
      transaction.response_transaction_id = refund.transaction_id
      transaction.membership_id = @member.current_membership_id
      transaction.created_at = refund.created_at
      transaction.updated_at = refund.updated_at
      transaction.save!

      if refund.message == "Success"
        add_operation(transaction.created_at, 'Transaction', transaction.id, "Refund success $#{transaction.amount}",
	              Settings.operation_types.credit, transaction.created_at, transaction.updated_at)
      else
        add_operation(transaction.created_at, 'Transaction', transaction.id, "Refund $#{transaction.amount} error: #{refund.message}",
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
  BillingChargeback.joins(' JOIN members ON refunds.member_id = members.id ').
	where(" refunds.imported_at IS NULL and refunds.phoenix_amount IS NOT NULL and refunds.phoenix_amount > 0.0 " +
                " and members.imported_at IS NOT NULL and message = 'Success' and refunds.campaign_id IS NOT NULL and refunds.campaign_id != 0" +
		" and refunds.reason not like '%Uncontroled%' ").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |refund|
      begin
        current_t = if [ 'Membership' ].include?(refund.class_name)
      	  BillingMembershipAuthorizationResponse.
        	  joins(' JOIN memberships ON memberships.id = membership_responses.membership_id '+
        		' JOIN members ON memberships.member_id = members.id ').
        	  where(" memberships.campaign_id != 0 and memberships.campaign_id IS NOT NULL and membership_responses.imported_at IS NOT NULL " + 
        		" AND membership_responses.phoenix_amount IS NOT NULL and membership_responses.phoenix_amount != 0.0 " +
        		" AND members.imported_at IS NOT NULL AND memberships.id = #{refund.class_id}").first
        elsif [ 'Enrollment' ].include?(refund.class_name)
      	  BillingEnrollmentAuthorizationResponse.
            joins(' JOIN enrollments ON enrollments.id = enrollment_responses.enrollment_id ' + 
                ' JOIN members ON enrollments.member_id = members.id ').
            where(" enrollments.campaign_id != 0 and enrollments.campaign_id IS NOT NULL and enrollment_responses.imported_at IS NOT NULL " + 
                " and enrollment_responses.phoenix_amount IS NOT NULL and enrollment_responses.phoenix_amount != 0.0 " + 
                " and enrollment_responses.message not like 'Failed%' " + # These transacciones have code == 0 :(
                " and members.imported_at IS NOT NULL AND enrollments.id = #{refund.class_id}").first
        end

	      next if current_t.nil?
	
        @member = current_t.member

        phoenix_t = PhoenixTransaction.find_by_member_id_and_created_at_and_updated_at_and_response_code @member.id, current_t.created_at, current_t.updated_at, '000'
        next if phoenix_t.nil?
        
        process_chargeback(refund, phoenix_t.terms_of_membership_id)
        if refund.message == 'Success'
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
  BillingChargeback.joins(' JOIN members ON refunds.member_id = members.id ').
	where(" refunds.imported_at IS NULL and refunds.phoenix_amount IS NOT NULL and refunds.phoenix_amount > 0.0 " +
          " and members.imported_at IS NOT NULL and message = 'Success'" +
		      " and refunds.reason like '%Uncontroled%' ").find_in_batches do |group|
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
      reasons = [ 'Membership' ]
      refunds = BillingChargeback.joins(' join membership_responses on refunds.class_id = membership_responses.membership_id ').
          where([ " refunds.imported_at IS NULL and refunds.phoenix_amount IS NOT NULL and refunds.phoenix_amount > 0.0 " +
            " and refunds.class_name IN (?) and membership_responses.transaction_id = ? ", 
            reasons, current_t.transaction_id ]).all
    when 'enrollment'
      reasons = [ 'Enrollment' ]
      refunds = BillingChargeback.joins(' join enrollment_responses on refunds.class_id = enrollment_responses.enrollment_id ').
          where([ " refunds.imported_at IS NULL and refunds.phoenix_amount IS NOT NULL " +
            " and refunds.class_name IN (?) and enrollment_responses.transaction_id = ? ", 
            reasons, current_t.transaction_id ]).all
  end
  refunds.each do |refund|
    process_chargeback(refund, phoenix_t.terms_of_membership_id)
    if refund.message == 'Success'
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
    joins(' JOIN enrollments ON enrollments.id = enrollment_responses.enrollment_id ' + 
  	' JOIN members ON enrollments.member_id = members.id ').
    where(" enrollments.campaign_id != 0 and enrollments.campaign_id IS NOT NULL and enrollment_responses.imported_at IS NULL " + 
  	" and enrollment_responses.phoenix_amount IS NOT NULL and enrollment_responses.phoenix_amount != 0.0 " + 
    " and enrollment_responses.code = '000' and members.imported_at IS NOT NULL " +
  "").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |response|
      authorization = BillingEnrollmentAuthorization.find_by_id response.enrollment_id
      unless authorization.nil? 
        begin
          tz = Time.now.utc
          @log.info "  * processing Enrollment Auth response ##{response.id}"
          @member = authorization.member
          unless @member.nil?
            transaction = PhoenixTransaction.new
            transaction.member_id = @member.id
            get_campaign_and_tom_id(authorization.campaign_id)
            transaction.terms_of_membership_id = @tom_id
            next if transaction.terms_of_membership_id.nil?
            transaction.gateway = response.phoenix_gateway
            transaction.set_payment_gateway_configuration(transaction.gateway)
            transaction.recurrent = false
            if @campaign.sale_authcapt == 1
              transaction.transaction_type = 'sale'
            else
              transaction.transaction_type = 'authorization_capture'
            end
            transaction.invoice_number = response.invoice_number(authorization)
            transaction.amount = response.amount
            transaction.response = response.message
            transaction.response_code = "%03d" % response.code.to_i
            transaction.response_result = response.message
            if response.code.to_i == 0
              transaction.response_transaction_id = authorization.transaction_id
            end
            transaction.success = (transaction.response_code == '000')
            transaction.membership_id = @member.current_membership_id
            transaction.created_at = response.created_at
            transaction.updated_at = response.updated_at
            transaction.refunded_amount = 0
            transaction.save!

            if transaction.response_code.to_i == 0
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
  joins(' JOIN memberships ON memberships.id = membership_responses.membership_id '+
	 ' JOIN members ON memberships.member_id = members.id ').
  where(" memberships.campaign_id != 0 and memberships.campaign_id IS NOT NULL and  membership_responses.imported_at IS NULL " + 
	 " AND membership_responses.phoenix_amount IS NOT NULL and membership_responses.phoenix_amount != 0.0 " +
	 " AND members.imported_at IS NOT NULL "
  ).find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |response|
      authorization = BillingMembershipAuthorization.find_by_id response.membership_id
      unless authorization.nil?
        begin
          tz = Time.now.utc
          @member = authorization.member
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
            if @campaign.sale_authcapt == 1
              transaction.transaction_type = 'sale'
            else
              transaction.transaction_type = 'authorization_capture'
            end
            transaction.invoice_number = response.invoice_number(authorization)
            transaction.amount = response.amount
            transaction.response = response.message
            transaction.response_code = "%03d" % response.code.to_i
            transaction.response_result = response.message
            if response.code.to_i == 0
              transaction.response_transaction_id = authorization.transaction_id
            end
            transaction.success = (transaction.response_code == '000')
            transaction.membership_id = @member.current_membership_id
            transaction.created_at = response.created_at
            transaction.updated_at = response.updated_at
            transaction.refunded_amount = 0
            transaction.save!
            if transaction.success
              set_last_billing_date_on_credit_card(@member, transaction.created_at)
              add_operation(transaction.created_at, 'Transaction', transaction.id, 
                            "Member billed successfully $#{transaction.amount} Transaction id: #{transaction.id}", 
                            Settings.operation_types.membership_billing, transaction.created_at, transaction.updated_at)
	            process_chargeback_from_transaction(transaction, authorization, 'membership')
            elsif [  "111", "126", "191", "301", "308", "310", "311", "321", "323",
                      "324", "325","326","327","328","351","352","353","354","357",
                      "360","362","363","364","365","366","367","369","400","610",
                      "611","612","701","702","703","705","706","712","714","950",
                      "951","952","953","954"  ].include?(transaction.response_code.to_s)
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



load_enrollment_transactions
load_membership_transactions
load_refunds_uncontrolled
# load_refunds_controlled



