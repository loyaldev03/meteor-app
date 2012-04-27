class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"

  def decline_strategy_not_found(message, transaction)
    @message = message
    @transaction = transaction
    mail :to => "platformadmins@xagax.com", :subject => "Decline rule not found #{Date.today} TID: #{transaction.id}"
  end

end
