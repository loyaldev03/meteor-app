class EmailTemplate < ActiveRecord::Base
  belongs_to :terms_of_membership
  handle_asynchronously :deliver!

  TEMPLATE_TYPES =  [ :welcome, :active, :cancel, :prebill, :refund ]

  CLIENTS = [ :amazon, :action_mailer, :lyris ]

  def lyris?
    self.client == :lyris
  end

  def action_mailer?
    self.client == :action_mailer
  end

  # def deliver!
  #   if lyris?
  #   elsif action_mailer?
  #     Notifier.signup(@user).deliver!
  #   else
  #     logger.error "* * * * * Client not supported"
  #   end
  # end

end
