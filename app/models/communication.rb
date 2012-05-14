class Communication < ActiveRecord::Base
  attr_accessible :email, :processed_at, :sent_success, :response
  belongs_to :member
  serialize :external_attributes

  def self.deliver!(template_type, member)
    template = EmailTemplate.find_by_terms_of_membership_id member.terms_of_membership_id
    c = Communication.new :email => member.email
    c.member_id = member.id
    c.template_name = template.name
    c.client = template.client
    c.external_attributes = template.external_attributes
    c.template_type = template.template_type
    c.scheduled_at = DateTime.now
    c.save
    if template.lyris?
      c.deliver_lyris
    elsif template.action_mailer?
      c.deliver_action_mailer
    else
      logger.error "* * * * * Client not supported"
    end
  end

# m = Member.find('dd76774a-9d03-4fe0-91f3-9537296d988e')
# Communication.deliver!('welcome', m)

  def deliver_lyris
    lyris = LyrisService.new
    # subscribe user
    lyris.subscribe_user!(self)
    response = lyris.send_email!(communication.external_attributes[:mlid], 
      communication.external_attributes[:trigger_id], email)
    update_attributes :sent_success => true, :processed_at => DateTime.now, :response => response
    Auditory.audit(nil, self, "Communication '#{template_name}' sent", member)
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => DateTime.now
    Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", member)
  end
  handle_asynchronously :deliver_lyris

  def deliver_action_mailer
    response = case template_type.to_sym
    when :welcome
      Notifier.welcome(email).deliver!
    when :cancellation
      Notifier.cancellation(email).deliver!
    when :prebill
      Notifier.pre_bill(email).deliver!
    when :refund
      Notifier.refund(email).deliver!
    else
      logger.error "Template type #{template_type} not supported."
    end
    update_attributes :sent_success => true, :processed_at => DateTime.now, :response => response
    Auditory.audit(nil, self, "Communication '#{template_name}' sent", member)
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => DateTime.now
    Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", member)
  end
  handle_asynchronously :deliver_action_mailer

end
