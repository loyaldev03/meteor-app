class Communication < ActiveRecord::Base
  attr_accessible :email, :processed_at, :sent_success, :response
  belongs_to :member
  serialize :external_attributes

  def self.deliver!(template_type, member)
    if member.email.include?("@noemail.com")
      message = "The email contains '@noemail.com' which is an empty email. The email won't be sent."
      Auditory.audit(nil, nil, message, member, Settings.operation_types["#{template_type}_email"])
    else
      if template_type.class == EmailTemplate
        template = template_type
      else
        template = EmailTemplate.find_by_terms_of_membership_id_and_template_type member.terms_of_membership_id, template_type
      end
      if template.nil?
        message = "Template does not exist type: '#{template_type}' and TOMID ##{member.terms_of_membership_id}"
        Airbrake.notify(:error_class => "Communication Template", :error_message => message, :parameters => { :member => member.inspect })
        logger.error "* * * * * Template does not exist"
      else
        c = Communication.new :email => member.email
        c.member_id = member.id
        c.template_name = template.name
        c.client = template.client
        c.external_attributes = template.external_attributes
        c.template_type = template.template_type
        c.scheduled_at = Time.zone.now
        c.save

        if template.lyris?
          c.deliver_lyris
        elsif template.action_mailer?
          c.deliver_action_mailer
        else
          message = "Client not supported: Template does not exist type: '#{template_type}' and TOMID ##{member.terms_of_membership_id}"
          Airbrake.notify(:error_class => "Communication Client", :error_message => message)
          logger.error "* * * * * Client not supported"
        end
      end
    end
  end

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
        member, Settings.operation_types["#{template_type}_email"])
    else
      response = lyris.send_email!(external_attributes[:mlid], external_attributes[:trigger_id], email)
      update_attributes :sent_success => true, :processed_at => Time.zone.now, :response => response
      Auditory.audit(nil, self, "Communication '#{template_name}' sent", member, Settings.operation_types["#{template_type}_email"])
    end
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => Time.zone.now
    Airbrake.notify(:error_class => "Communication deliver_lyris", :error_message => e, :parameters => { :member => member.inspect, 
      :current_membership => member.current_membership.inspect, :communication => self.inspect })
    Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", member, Settings.operation_types["#{template_type}_email"])
  end
  handle_asynchronously :deliver_lyris


  def deliver_action_mailer
    response = case template_type.to_sym
    when :active
      Notifier.active(email).deliver!
    when :cancellation
      Notifier.cancellation(email).deliver!
    when :prebill
      Notifier.pre_bill(email).deliver!
    when :refund
      Notifier.refund(email).deliver!
    when :pillar
      Notifier.pillar(email).deliver!
    when :pillar_provisional
      Notifier.pillar_provisional(email).deliver!
    when :hard_decline
      Notifier.hard_decline(member).deliver!
    when :soft_decline
      Notifier.soft_decline(member).deliver!
    else
      message = "Deliver action could not be done."
      Airbrake.notify(:error_class => "Communication Delivery", :error_message => message, :parameters => { :member => member.inspect, :communication => self.inspect })
      logger.error "Template type #{template_type} not supported."
    end
    update_attributes :sent_success => true, :processed_at => Time.zone.now, :response => response
    Auditory.audit(nil, self, "Communication '#{template_name}' sent", member, Settings.operation_types["#{template_type}_email"])
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => Time.zone.now
    Airbrake.notify(:error_class => "Communication deliver_lyris", :error_message => e, :parameters => { :member => member.inspect, :communication => self.inspect })
    Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", member, Settings.operation_types["#{template_type}_email"])
  end
  handle_asynchronously :deliver_action_mailer

end