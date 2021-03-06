class Notifier < ActionMailer::Base
  layout 'mailer', only: %i[shipping_cost_updater_result]
  default from: Settings.platform_email
  default bcc: Settings.platform_admins_email

  def pre_bill(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "Pre bill email to #{email}"
  end

  def manual_payment_pre_bill(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "Manual Payment Pre bill email to #{email}"
  end

  def cancellation(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "cancellation to #{email}"
  end

  def rejection(email)
    to = Rails.env == 'prototype' ? Settings.email_to_use_on_action_mailer_as_recipient : email
    mail :to => to, :subject => "rejection to #{email}"
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

  def active_with_approval(emails,user)
    @user = user
    mail :to => emails, :subject => "User activation needs approval"
  end

  def recover_with_approval(emails,user)
    @user = user
    mail :to => emails, :subject => "User recovering needs approval"
  end

  def call_these_users(csv, contact_email_list)
    return unless contact_email_list.present?
    attachments["call_users_#{Date.today}.csv"] = { :mime_type => 'text/csv', :content => csv }
    mail :to => contact_email_list, 
         :subject => "Account Updater [#{Date.today}] - List of users to contact.",
         :bcc => Settings.platform_admins_email
  end

  def hard_decline(user)
    @user = user
    mail :to => user.email, :subject => "Membership cancellation [#{Rails.env}] - #{I18n.l(Time.zone.now, :format => :default )}"
  end

  def soft_decline(user)
    @user = user
    mail :to => user.email, :subject => "Membership cancellation [#{Rails.env}] - #{I18n.l(Time.zone.now, :format => :default )}"
  end

  def product_list(product_xls_file)
    attachments["product_list_#{Date.today}.xlsx"] = File.read(product_xls_file)
    mail :to => Settings.email_to_send_product_list, 
         :subject => "#{I18n.l(Time.zone.now, :format => :default )} - Product list"
  end

  def product_bulk_process_result(product_xls_file, email)
    attachments["product_bulk_process_result#{Date.today}.xlsx"] = File.read(product_xls_file)
    mail :to => email,
         :subject => "#{I18n.l(Time.zone.now, :format => :default )} - Product Bulk Process Results"
  end

  def manual_fulfillment_file(agent, fulfillment_file, file)
    attachments["fulfillments_xls_file_##{fulfillment_file.id}.xlsx"] = File.read(file)
    mail :to => agent.email, :subject => "Fulfillment file ##{fulfillment_file.id}"
  end

  def shipping_cost_updater_result(file_names_processed, success_count, errors)
    @file_names_processed = file_names_processed
    @success_count        = success_count
    @errors               = errors
    mail to: Settings.shipping_cost_report_recipient,
         subject: "#{I18n.l(Time.zone.now, format: :default)} - Shipment Updater Results"
  end
end
