class EmailTemplate < ActiveRecord::Base
  belongs_to :terms_of_membership
  serialize :external_attributes

  TEMPLATE_TYPES =  [ :welcome, :active, :cancellation, :prebill, :prebill_renewal, :refund ]

  CLIENTS = [ :amazon, :action_mailer, :lyris ]

  def lyris?
    self.client == 'lyris'
  end

  def action_mailer?
    self.client == 'action_mailer'
  end

end
