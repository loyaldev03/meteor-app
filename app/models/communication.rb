class Communication < ActiveRecord::Base
  attr_accessible :email, :run_at, :sent, :response
  belongs_to :member

  def self.deliver!(template_type, member)
    template = EmailTemplate.find_by_terms_of_membership_id member.terms_of_membership_id
    c = Communication.new :email => member.email
    c.member_id = member.id
    c.template_name = template.name
    c.client = template.client
    c.external_id = template.external_id
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

  def deliver_lyris
    raise "error not defined yet!!!"
  end
  handle_asynchronously :deliver_lyris

  def deliver_action_mailer
    case template_type.to_sym
    when :welcome
      Notifier.welcome(member.email).deliver!
    when :cancellation
      Notifier.cancellation(member.email).deliver!
    when :prebill
      Notifier.pre_bill(member.email).deliver!
    when :refund
      Notifier.refund(member.email).deliver!
    else
      logger.error "Template type #{template_type} not supported."
    end
    update_attributes :sent_success => true, :processed_at => DateTime.now
    Auditory.audit(nil, self, "Communication '#{template_name}' sent", member)
  rescue Exception => e
    logger.error "* * * * * #{e}"
    update_attributes :sent_success => false, :response => e, :processed_at => DateTime.now
    Auditory.audit(nil, self, "Error while sending communication '#{template_name}'.", member)
  end
  handle_asynchronously :deliver_action_mailer

end
