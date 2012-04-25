class User < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :domain

  include Extensions::UUID

  def enroll(member, credit_card, amount)
    if amount.to_f != 0.0
      # TODO: el transaction type tiene que venir del TOM?????
      t = Transaction.new
      t.transaction_type = "sale"
      t.prepare(member, credit_card, amount, member.terms_of_membership.payment_gateway_configuration)
      answer = t.sale
      unless t.success?
        Auditory.audit!(self, answer)
        return answer
      end
    end

    begin
      member.join_date = DateTime.now
      member.save!
      # if amount.to_f == 0.0 => TODO: we should activate this member!!!!
      message = "Member enrolled successfully"
      Auditory.audit!(member, message)
      { :message => message, :code => "000" }
    rescue Exception => e
      # TODO: Notify devels about this!
      # TODO: this can happend if in the same time a new member is enrolled that makes this
      #     an invalid one. we should revert the transaction.
      message = "Could not save member. #{e}"
      Auditory.audit!(member, message)
      { :message => message, :code => 404 }
    end
  end
end
