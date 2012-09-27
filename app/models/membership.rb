class Membership < ActiveRecord::Base
  belongs_to :terms_of_membership
  belongs_to :member
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  has_one :enrollment_info
  has_many :transactions

  attr_accessible :created_by, :join_date, :status, :cancel_date, :quota

  after_create :set_current_membership_at_member

  delegate :active_credit_card, :to => :member
  delegate :recycled_times, :to => :member

  def self.datatable_columns
    ['id' ]
  end

  def bill
    amount = terms_of_membership.installment_amount
    if amount.to_f > 0.0
      # Grace period
      # why cero times? Because only 1 time must be Billed.
      # Before we were using times = 1. Problem is that times = 1, on case logic will allow times values [0,1].
      # So grace period will be granted twice.
      #        limit = 0 
      #        days  = campaign.grace_period
      if active_credit_card.nil?
        if terms_of_membership.grace_period > 0
          { :code => Settings.error_codes.credit_card_blank_with_grace, 
            :message => "Credit card is blank. Allowing grace period" }
        else
          { :code => Settings.error_codes.credit_card_blank_without_grace,
            :message => "Credit card is blank and grace period is disabled" }
        end
      elsif terms_of_membership.payment_gateway_configuration.nil?
        message = "TOM ##{terms_of_membership.id} does not have a gateway configured."
        Auditory.audit(nil, terms_of_membership, message, member, Settings.operation_types.membership_billing_without_pgc)
        Airbrake.notify(:error_class => "Billing", :error_message => message, :parameters => { :member => member.inspect, :membership => self.inspect })
        { :code => Settings.error_codes.tom_wihtout_gateway_configured, :message => message }
      else
        acc = CreditCard.recycle_expired_rule(active_credit_card, recycled_times)
        trans = Transaction.new
        trans.transaction_type = "sale"
        trans.prepare(member, acc, amount, terms_of_membership.payment_gateway_configuration)
        answer = trans.process
        if trans.success?
          member.assign_club_cash!
          member.set_as_active!
          member.schedule_renewal
          message = "Member billed successfully $#{amount} Transaction id: #{trans.id}"
          Auditory.audit(nil, trans, message, member, Settings.operation_types.membership_billing)
          { :message => message, :code => Settings.error_codes.success, :member_id => member.id }
        else
          message = member.set_decline_strategy(trans)
          answer # TODO: should we answer set_decline_strategy message too?
        end
      end
    else
      { :message => "Called billing method but no amount on TOM is set.", :code => Settings.error_codes.no_amount }
    end
  end
  
  private
    def set_current_membership_at_member
      self.member.update_attribute :current_membership_id, self.id
    end

end

