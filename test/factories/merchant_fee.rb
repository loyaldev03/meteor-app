FactoryBot.define do

  factory :merchant_fee_payeezy, class: MerchantFee do
    sequence(:name) {|n| "merchantfee_#{Faker::Lorem.characters(10)}" }
    gateway "payeezy"    
    transaction_types {['authorization','sale','refund','credit', 'chargeback', 'rebutted_chargeback']}
    rate 0.4
    unit_cost 0.01
    apply_on_decline true
  end
end


