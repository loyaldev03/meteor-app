class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"
  #default bcc: "platformadmins@xagax.com"
  
  def prebill_renewal(email)
    mail :to => Settings.email_to_use_on_action_mailer_as_recipient, :subject => "Renewal Pre bill email to #{email}"
  end

  def pre_bill(email)
    mail :to => Settings.email_to_use_on_action_mailer_as_recipient, :subject => "Pre bill email to #{email}"
  end

  def cancellation(email)
    mail :to => Settings.email_to_use_on_action_mailer_as_recipient, :subject => "cancellation to #{email}"
  end

  def active(email)
    mail :to => Settings.email_to_use_on_action_mailer_as_recipient, :subject => "active to #{email}"
  end

  def refund(email)
    mail :to => Settings.email_to_use_on_action_mailer_as_recipient, :subject => "refund to #{email}"
  end

  def active_with_approval(agent,member)
    @agent = agent
    @member = member
    mail :to => agent.email, :subject => "Member activation needs approval"
  end

  def recover_with_approval(agent,member)
    @agent = agent
    @member = member
    mail :to => agent.email, :subject => "Member recovering needs approval"
  end

  def call_these_members(csv)
    subject    "AUS answered CALL to these members #{Date.today}"
    bcc        'platformadmins@xagax.com'
    recipients Settings.call_these_members_recipients
    attachment :content_type => "text/csv", :filename => "call_members_#{Date.today}.csv" do |a|
      a.body = csv
    end
  end

end
