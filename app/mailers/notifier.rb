class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"
  default bcc: "platformadmins@xagax.com"

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
