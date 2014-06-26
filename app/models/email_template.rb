class EmailTemplate < ActiveRecord::Base
  attr_accessible :name, :client, :template_type, :days_after_join_date, :external_attributes
  
  belongs_to :terms_of_membership
  serialize :external_attributes

  TEMPLATE_TYPES = [
    :active,                  # Sent when member changes its status to active
    :cancellation,            # Sent when member changes its status to lapsed
    :rejection,               # Sent when member is in applied status, and it is rejected by one of our agents
    :prebill,                 # Sent 7 days before we bill member
    :manual_payment_prebill,  # Sent 14 days before next billing day.
    :refund,                  # Sent when CS does a refund.
    :birthday,                # Sent if birthday is on enrollment_info
    :pillar,                  # Emails sent after join date and active/prov status. they use days_after_join_date attribute
    :hard_decline,            # Emails sent when hard decline happens
    :soft_decline             # Emails sent when soft decline happens  
  ]

  CLIENTS = [ :exact_target, :action_mailer, :lyris ]

  validates :name, :template_type, :terms_of_membership_id, :client,
    :presence => :true,
    length: { maximum: 255, too_long: "%{count} characters is the maximum allowed" }
  
  validates :external_attributes, length: { maximum: 2048, too_long: "%{count} characters is the maximum allowed" }
  
  validates :days_after_join_date, numericality: { only_integer: true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1000 }, :if => :is_pillar?

  def lyris?
    self.client == 'lyris'
  end

  def action_mailer?
    self.client == 'action_mailer'
  end

  def exact_target?
    self.client == 'exact_target'
  end

  def self.datatable_columns
    [ 'id', 'name', 'template_type', 'days_after_join_date' ]
  end

  def is_pillar?
    self.template_type == 'pillar'
  end

end
