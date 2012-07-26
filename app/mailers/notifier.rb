class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"
  default bcc: "platformadmins@xagax.com"
  
  def prebill_renewal(email)
    email = nil
    mail :to => email, :subject => "Renewal Pre bill email"
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

  def active_with_approval(agent,member)
    @agent = agent
    @member = member
    mail :to => agent.email, :subject => "active with approval"
  end

  def recover_with_approval(agent,member)
    @agent = agent
    @member = member
    mail :to => agent.email, :subject => "recover with approval"
  end

end
