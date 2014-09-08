class Communication < ActiveRecord::Base
  attr_accessible :email, :processed_at, :sent_success, :response
  belongs_to :user
  serialize :external_attributes

  def self.deliver!(template_type, user)
    if user.email.include?("@noemail.com")
      message = "The email contains '@noemail.com' which is an empty email. The email won't be sent."
      Auditory.audit(nil, nil, message, user, Settings.operation_types.no_email_error)
    else
      if template_type.class == EmailTemplate
        template = template_type
      else
        template = EmailTemplate.where(terms_of_membership_id: user.terms_of_membership_id, template_type: template_type, client: user.club.marketing_tool_client).first
      end
      if template.nil?
        message = "'#{template_type}' and TOMID ##{user.terms_of_membership_id}"
        logger.error "* * * * * Template does not exist - Template missing: " + message + " - Member: #{user.inspect}"
      else
        c = Communication.new :email => user.email
        c.user_id = user.id
        c.template_name = template.name
        c.client = template.client
        c.external_attributes = template.external_attributes
        c.template_type = template.template_type
        c.scheduled_at = Time.zone.now
        c.save

        if template.lyris?
          c.deliver_lyris
        elsif template.exact_target?
          c.deliver_exact_target
        elsif template.mandrill?
          c.deliver_mandrill
        elsif template.action_mailer?
          c.deliver_action_mailer
        else
          message = "Client not supported: Template does not exist type: '#{template_type}' and TOMID ##{user.terms_of_membership_id}"
          Auditory.report_issue("Communication Client", message)
          logger.error "* * * * * Client not supported"
        end
      end
    end
  end

  def deliver_exact_target
    if self.user.exact_target_member
      result = self.user.exact_target_member.send_email(external_attributes[:customer_key])
      self.sent_success = (result.OverallStatus == "OK")
      self.processed_at = Time.zone.now
      self.response = result
      self.save!
      Auditory.audit(nil, self, "Communication '#{template_name}' scheduled", user, Settings.operation_types["#{template_type}_email"])
    else
      update_attributes :sent_success => false, :response => I18n.t('error_messages.no_marketing_client_configure') , :processed_at => Time.zone.now
    end
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => Time.zone.now
    unless e.to_s.include?("Timeout")
      Auditory.report_issue("Communication deliver_exact_target", e, { :user => user.inspect, 
        :current_membership => user.current_membership.inspect, :communication => self.inspect })
      Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", user, Settings.operation_types["#{template_type}_email"])
    end
  end  
  handle_asynchronously :deliver_exact_target, :queue => :exact_target_email, priority: 15

  def deliver_mandrill
    if self.user.mandrill_member
      result = self.user.mandrill_member.send_email(external_attributes[:template_name])
      self.sent_success = (result["status"]=="sent")
      self.processed_at = Time.zone.now
      self.response = result
      self.save!
      Auditory.audit(nil, self, "Communication '#{template_name}' scheduled", user, Settings.operation_types["#{template_type}_email"])
    else
      update_attributes :sent_success => false, :response => I18n.t('error_messages.no_marketing_client_configure') , :processed_at => Time.zone.now
    end
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => Time.zone.now
    unless e.to_s.include?("Timeout")
      Auditory.report_issue("Communication deliver_mandrill", e, { :user => user.inspect, 
        :current_membership => user.current_membership.inspect, :communication => self.inspect })
      Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", user, Settings.operation_types["#{template_type}_email"])
    end
  end
  handle_asynchronously :deliver_mandrill, :queue => :mandrill_email, priority: 15

  def deliver_lyris
    lyris = LyrisService.new
    # subscribe user
    lyris.site_id = external_attributes[:site_id]
    lyris.subscribe_user!(self)
    if lyris.unsubscribed?(external_attributes[:mlid], email)
      update_attributes :sent_success => false, 
          :response => "Member requested unsubscription to mlid #{external_attributes[:mlid]} at lyris", 
          :processed_at => Time.zone.now
      Auditory.audit(nil, self, "Communication '#{template_name}' wont be sent because email is unsubscribed", 
        user, Settings.operation_types["#{template_type}_email"])
    else
      response = lyris.send_email!(external_attributes[:mlid], external_attributes[:trigger_id], email)
      update_attributes :sent_success => true, :processed_at => Time.zone.now, :response => response
      Auditory.audit(nil, self, "Communication '#{template_name}' sent", user, Settings.operation_types["#{template_type}_email"])
    end
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => Time.zone.now
    Auditory.report_issue("Communication deliver_lyris", e, { :user => user.inspect, 
      :current_membership => user.current_membership.inspect, :communication => self.inspect })
    Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", user, Settings.operation_types["#{template_type}_email"])
  end
  handle_asynchronously :deliver_lyris, :queue => :lyris_email, priority: 15


  def deliver_action_mailer
    response = case template_type.to_sym
    when :cancellation
      Notifier.cancellation(email).deliver!
    when :rejection
      Notifier.rejection(email).deliver!
    when :prebill
      Notifier.pre_bill(email).deliver!
    when :manual_payment_prebill
      Notifier.manual_payment_pre_bill(email).deliver!
    when :refund
      Notifier.refund(email).deliver!
    when :birthday
      Notifier.birthday(email).deliver!
    when :pillar
      Notifier.pillar(email).deliver!
    when :hard_decline
      Notifier.hard_decline(user).deliver!
    when :soft_decline
      Notifier.soft_decline(user).deliver!
    else
      message = "Deliver action could not be done."
      Auditory.report_issue("Communication deliver_action_mailer", message, { :user => user.inspect, :communication => self.inspect })
      logger.error "Template type #{template_type} not supported."
    end
    update_attributes :sent_success => true, :processed_at => Time.zone.now, :response => response
    Auditory.audit(nil, self, "Communication '#{template_name}' sent", user, Settings.operation_types["#{template_type}_email"])
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => Time.zone.now
    Auditory.report_issue("Communication deliver_action_mailer", e, { :user => user.inspect, :communication => self.inspect })
    Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", user, Settings.operation_types["#{template_type}_email"])
  end
  handle_asynchronously :deliver_action_mailer, :queue => :email_queue, priority: 15

end