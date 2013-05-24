class EmailTemplate < ActiveRecord::Base
  attr_accessible :name, :client, :template_type
  
  belongs_to :terms_of_membership
  serialize :external_attributes

  TEMPLATE_TYPES =  [ :active, # sent when member changes its status to active
    :cancellation, # sent when member changes its status to lapsed
    :rejection, # sent when member is in applied status, and it is rejected by one of our agents
    :prebill, # sent 7 days before we bill member
    :refund, # sent when CS does a refund.
    :birthday, # sent if birthday is on enrollment_info
    :pillar, # emails sent after join date and active/prov status. they use days_after_join_date attribute
    :hard_decline, # emails sent when hard decline happens
    :soft_decline # emails sent when soft decline happens  
  ]

  validates :name, :template_type, :terms_of_membership_id, :presence => :true

  CLIENTS = [ :amazon, :action_mailer, :lyris ]

  def lyris?
    self.client == 'lyris'
  end

  def action_mailer?
    self.client == 'action_mailer'
  end

end
