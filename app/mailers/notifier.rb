class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"
  default bcc: "platformadmins@xagax.com"
  
  def prebill_renewal(email)
    destination = (Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email)
    mail :to => destination, :subject => "Renewal Pre bill email to #{email}"
  end

  def pre_bill(email)
    destination = (Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email)
    mail :to => destination, :subject => "Pre bill email to #{email}"
  end

  def cancellation(email)
    destination = (Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email)
    mail :to => destination, :subject => "cancellation to #{email}"
  end

  def active(email)
    destination = (Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email)
    mail :to => destination, :subject => "active to #{email}"
  end

  def refund(email)
    destination = (Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email)
    mail :to => destination, :subject => "refund to #{email}"
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
    attachments["call_members_#{Date.today}.csv"] = { :mime_type => 'text/csv', :content => csv }
    mail :to => Settings.call_these_members_recipients, 
         :subject => "AUS answered CALL to these members #{Date.today}",
         :bcc => 'platformadmins@xagax.com'
  end

end
