class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"
  default bcc: "platformadmins@xagax.com"
  
  def pre_bill(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "Pre bill email to #{email}"
  end

  def cancellation(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "cancellation to #{email}"
  end

  def rejection(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "rejection to #{email}"
  end
  def active(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "active to #{email}"
  end

  def refund(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "refund to #{email}"   
  end

  def birthday(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "Happy birthday #{email}"
  end
  
  def pillar(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "pillar to #{email}"
  end

  def active_with_approval(emails,member)
    @member = member
    mail :to => emails, :subject => "Member activation needs approval"
  end

  def recover_with_approval(emails,member)
    @member = member
    mail :to => emails, :subject => "Member recovering needs approval"
  end

  def call_these_members(csv)
    attachments["call_members_#{Date.today}.csv"] = { :mime_type => 'text/csv', :content => csv }
    mail :to => Settings.call_these_members_recipients, 
         :subject => "AUS answered CALL to these members #{Date.today}",
         :bcc => 'platformadmins@xagax.com'
  end

  def members_with_duplicated_email_sync_error(member_list)
    @members = member_list
    mail :to => Settings.email_to_use_on_duplicated_email_sync_error,
         :subject => "[#{Rails.env}] - #{I18n.l(Time.zone.now, :format => :default )} - Duplicated email sync error."
  end

  def hard_decline(member)
    @member = member
    mail :to => member.email, :subject => "Membership cancellation [#{Rails.env}] - #{I18n.l(Time.zone.now, :format => :default )}"
  end

  def soft_decline(member)
    @member = member
    mail :to => member.email, :subject => "Membership cancellation [#{Rails.env}] - #{I18n.l(Time.zone.now, :format => :default )}"
  end

  def product_list(product_xls_file)
    attachments["product_list_#{Date.today}.xlsx"] = File.read(product_xls_file)
    mail :to => Settings.email_to_send_product_list, 
         :subject => "[#{Rails.env}] - #{I18n.l(Time.zone.now, :format => :default )} - Product list"
  end

  def fulfillment_naamma_report(fulfillment_xls_file, quantity)
    @quantity = quantity
    attachments["fulfillments_xls_file#{Date.today}.xlsx"] = File.read(fulfillment_xls_file)
    mail :to => Rails.env=='production' ? 'bmiller@naamma.com,clawler@stoneacreinc.com,ddanch@stoneacreinc.com' : 'clawler@stoneacreinc.com',
         :subject => "#{I18n.l(Time.zone.now, :format => :default )} - NAAMMA fulfillments report"
  end

end
 

