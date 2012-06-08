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

def load_transactions
  BillingEnrollmentAuthorizationResponse.find_in_batches do |group|
    group.each do |response|
      tz = Time.now
      begin
        @log.info "  * processing Auth response ##{response.id}"
        if response.member.nil?
          @log.info "  * Member id not found for Auth response ##{response.id} member id ##{response.authorization.member_id}"
        else
          transaction = PhoenixTransaction.new
          transaction.member_id = response.member.uuid


 => #<BillingEnrollmentAuthorizationResponse id: 1, authorization_id: 1, code: "0", message: "Welcome Member: 1", 
 created_at: "2011-04-30 14:16:59", updated_at: "2011-04-30 14:16:59"> 
 => #<BillingEnrollmentAuthorization id: 1, member_id: 1, authorized: 1, authorized_date: "2011-04-30 14:16:59",
  litleTxnId: 819793458743788949, auth_code: nil, captured: 0, captured_date: "2011-04-30 14:16:59", times: nil, 
  campaign_id: 57, created_at: "2011-04-30 14:16:59", updated_at: "2011-04-30 14:16:59"> 

          transaction.terms_of_membership_id = get_terms_of_membership_id(response.authorization.campaign_id)
          transaction.payment_gateway_configuration = transaction.terms_of_membership.payment_gateway_configuration
          transaction.gateway = 'litle'
          transaction.recurrent = false
          transaction.transaction_type = 'authorization_capture'
          transaction.invoice_number = "#{response.created_at}-#{response.authorization.member_id}"
          transaction.amount = response.amount

          response: Store auth and capt message , as a hash
          response_code: Store capt code if available, if not store auth code
          response_result: Store capt message if available, if not store auth message
          response_transaction_id: Store capture litleTxnId if available, if not store auth litleTxnId
          response_auth_code: Store auth_code
          created_at: use capt/auth created_at
          updated_at: NOW
          credit_card_id: blank [2]
          refunded_amount: fixed value '0'
          Add operation

          add_operation(op.operation_date, nil, op.name, Settings.operation_types.recovery, op.created_on, op.updated_on, op.author_id)
          @member.increment!(:reactivation_times)
          op.destroy

      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
      @log.info "    ... took #{Time.now - tz} for CS operation ##{op.id}"
    end
  end
end


load_transactions
load_refunds

