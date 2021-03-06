class EmailTemplate < ActiveRecord::Base
  belongs_to :terms_of_membership
  serialize :external_attributes

  TEMPLATE_TYPES = [
    :cancellation,            # Sent when member changes its status to lapsed
    :rejection,               # Sent when member is in applied status, and it is rejected by one of our agents
    :prebill,                 # Sent a pre-specified number of days before billing the member.
    :manual_payment_prebill,  # Sent 14 days before next billing day.
    :refund,                  # Sent when CS does a refund.
    :birthday,                # Sent if birth day is present on user's model.
    :pillar,                  # Emails sent after join date and active/prov status. they use days attribute
    :hard_decline,            # Emails sent when hard decline happens
    :soft_decline,            # Emails sent when soft decline happens
    :membership_bill,         # Emails sent when successfully billing user's memberships
    :membership_renewal       # Emails sent when successfully billing user's memberships. We only send this communication if the user is already in active status when billing.
  ]

  CLIENTS = [ :exact_target, :action_mailer, :lyris ]

  validates :name, :template_type, :terms_of_membership_id, :client, presence: :true

  validates :name, uniqueness: { scope: [:terms_of_membership_id, :client] }

  validates :template_type, uniqueness: { scope: [:terms_of_membership_id, :client] }, unless: :is_pillar?
  
  validates :external_attributes, length: { maximum: 2048 }
  
  validates :days, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }, if: lambda { |record| record.is_pillar? or record.is_prebill? }

  def self.external_attributes_related_to_client(client)
    case client
    when "action_mailer"
      {required: [], optional: []}
    when 'exact_target'
      {required: ['customer_key'], optional: []}
    when 'mailchimp_mandrill'
      {required: ['template_name'], optional: ['subaccount']}
    when 'lyris'
      {required: ['trigger_id', 'mlid', 'site_id'], optional: []}
    else
      {required: [], optional: []}
    end
  end

  def self.template_types_helper(type)
    case type
    when :cancellation
      "Sent when member changes its status to lapsed."
    when :rejection
      "Sent when member is in applied status, and it is rejected by one of our agents."
    when :prebill
      "Sent a pre-specified number of days before billing the member."
    when :manual_payment_prebill
      "Sent 14 days before next billing day."
    when :refund
      "Sent when doing a refund."
    when :birthday
      "Sent if birth day is present on user's model."
    when :pillar
      "Emails sent a certain amount of days after join date on active and provisional members."
    when :hard_decline
      "Emails sent when hard decline happens."
    when :soft_decline
      "Emails sent when soft decline happens."
    when :membership_bill
      "Emails sent when successfully billing user's memberships."
    when :membership_renewal
      "Emails sent when successfully billing user's memberships. This communication is only send when the user is in active status."
    end
  end
  
  def self.clients_options
    clients = [ ['Exact Target', 'exact_target'], ['Mailchimp/Mandrill', 'mailchimp_mandrill'] ]
    clients << ['Action Mailer', 'action_mailer'] unless Rails.env.production?
    clients
  end

  def lyris?
    self.client == 'lyris'
  end

  def action_mailer?
    self.client == 'action_mailer'
  end

  def exact_target?
    self.client == 'exact_target'
  end

  def mandrill?
    self.client == 'mailchimp_mandrill'
  end

  def self.datatable_columns
    [ 'id', 'name', 'template_type', 'client' ]
  end

  def is_pillar?
    self.template_type.to_s == 'pillar'
  end

  def is_prebill?
    self.template_type.to_s == 'prebill'
  end

  def fetch_external_attributes_data
    self.external_attributes ? self.external_attributes.to_query : ''
  end

end
