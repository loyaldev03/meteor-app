class AddCreditCardTypeAtTransactionsTable < ActiveRecord::Migration
  def up
    add_column :transactions, :cc_type, :string
    Transaction.all.each do |x|
      ActiveMerchant::Billing::CreditCard.require_verification_value = false
      @cc = ActiveMerchant::Billing::CreditCard.new(
        :number     => x.number,
        :month      => x.expire_month,
        :year       => x.expire_year,
        :first_name => x.first_name,
        :last_name  => x.last_name
      )
      @cc.valid?
      # we will use ActiveMerchant::Billing::CreditCardMethods::CARD_COMPANIES.keys
      # ["switch", "visa", "diners_club", "master", "forbrugsforeningen", "dankort", 
      #    "laser", "american_express", "solo", "jcb", "discover", "maestro"]
      x.cc_type = @cc.type
      x.save
    end
  end
  def down
    remove_column :transactions, :cc_type
  end
end
