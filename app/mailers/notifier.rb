class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"
  default bcc: "platformadmins@xagax.com"

  def decline_strategy_not_found(message, transaction)
    @message = message
    @transaction = transaction
    email = nil
    mail :to => "platformadmins@xagax.com", :subject => "Decline rule not found #{Date.today} TID: #{transaction.id}"
  end

  def pre_bill(email)
    email = nil
    mail :to => email, :subject => "Pre bill email"
  end

  def cancellation(email)
    email = nil
    mail :to => email, :subject => "cancellation"
  end

  def active(email)
    email = nil
    mail :to => email, :subject => "active"
  end

  def refund(email)
    email = nil
    mail :to => email, :subject => "refund"
  end

end
