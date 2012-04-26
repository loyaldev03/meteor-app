class User < ActiveRecord::Base
  include Extensions::UUID

  attr_accessible :ip_address, :user_agent
  
  belongs_to :domain
  has_many :transactions

  def enroll(member, credit_card, amount, agent = nil)
    if amount.to_f != 0.0
      trans = Transaction.new
      # TODO: el transaction type tiene que venir del TOM?????
      trans.transaction_type = "sale"
      trans.prepare(member, credit_card, amount, member.terms_of_membership.payment_gateway_configuration)
      answer = trans.process
      unless trans.success?
        Auditory.audit(agent, self, answer)
        Auditory.add_redmine_ticket
        return answer
      end
    end

    begin
      member.join_date = DateTime.now
      member.save!
      credit_card.member = member
      credit_card.save!
      if trans
        # We cant assign this information before , because models must be created AFTER transaction
        # is completed succesfully
        trans.member_id = member.id
        trans.credit_card_id = credit_card.id
        trans.save
        credit_card.accepted_on_billing
      end
      # if amount.to_f == 0.0 => TODO: we should activate this member!!!!
      message = "Member enrolled successfully"
      Auditory.audit(agent, member, message)
      { :message => message, :code => "000", :member_id => member.id }
    rescue Exception => e
      # TODO: Notify devels about this!
      # TODO: this can happend if in the same time a new member is enrolled that makes this
      #     an invalid one. we should revert the transaction.
      message = "Could not save member. #{e}"
      Auditory.audit(agent, member, message)
      { :message => message, :code => 404 }
    end
  end
end
