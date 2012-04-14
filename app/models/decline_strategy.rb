# credit_card_type will try to have the same values than ActiveMerchant::Billing::CreditCardMethods::CARD_COMPANIES.keys
# ["switch", "visa", "diners_club", "master", "forbrugsforeningen", "dankort", "laser", "american_express", "solo", "jcb", "discover", "maestro"]
class DeclineStrategy < ActiveRecord::Base
  acts_as_paranoid

  def soft_decline?
    self.decline_type == 'soft'
  end
  def hard_decline?
    self.decline_type == 'hard'
  end
end
