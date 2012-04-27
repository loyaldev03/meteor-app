class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"

  def decline_strategy_not_found(message, transaction)
    recipients "platformadmins@xagax.com"
    subject    "Decline rule not found #{Date.today}"
    body :message => message, :transaction => transaction
  end

end
