class User < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :domain

  def enroll!(member, credit_card, amount)
    if amount.to_f == 0.0
      { :message => "Member enrolled successfully", :code => "000" }
    else
      # TODO: el transaction type tiene que venir de la config del gateway
      t = Transaction.new :transaction_type => "sale"
      t.member = member
      t.credit_card = credit_card
      t.amount = amount
      t.payment_gateway_configuration = member.terms_of_membership.payment_gateway_configuration
      t.save
    end


  end
end
