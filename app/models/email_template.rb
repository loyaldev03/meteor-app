class EmailTemplate < ActiveRecord::Base
  belongs_to :terms_of_membership
  serialize :external_attributes

  TEMPLATE_TYPES =  [ :welcome, # welcome email is sent by drupal
    :active, # sent when member changes its status to active
    :cancellation, # sent when member changes its status to lapsed
    :prebill, # sent 7 days before we bill member
    :prebill_renewal, # not used yet
    :refund, # sent when CS does a refund.
    :pillar # emails sent after join date. they use days_after_join_date attribute
  ]

  CLIENTS = [ :amazon, :action_mailer, :lyris ]

  def lyris?
    self.client == 'lyris'
  end

  def action_mailer?
    self.client == 'action_mailer'
  end

end
