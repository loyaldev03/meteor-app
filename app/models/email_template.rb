class EmailTemplate < ActiveRecord::Base
  belongs_to :terms_of_membership

  TEMPLATE_TYPES =  [ :welcome, :active, :deactivation, :prebill, :refund ]

  CLIENTS = [ :amazon, :action_mailer, :lyris ]

  def lyris?
    self.client == 'lyris'
  end

  def action_mailer?
    self.client == 'action_mailer'
  end

end
