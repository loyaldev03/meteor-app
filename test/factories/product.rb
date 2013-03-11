FactoryGirl.define do

  factory :product do
    name "Bracelet"
    package "NCARFLAG"
    sku "Bracelet"
    cost_center "Bracelet"
    stock 10
    weight 5
  end

  factory :product_without_stock_and_not_recurrent, class: Product do
    name "Circlet"
    package "NCARFLAG"
    sku "circlet"
    cost_center "circlet"
    stock 0
    recurrent false
  end  	

  factory :product_without_stock_and_recurrent, class: Product do
    name "Kit kard"
    package "NCARFLAG"
    cost_center "kit-card"
    sequence(:sku) {|n| Settings.kit_card_product+"#{n}" }
    recurrent true
    stock 0
  end 

  factory :product_with_recurrent, class: Product do
    name "Kit kard"
    package "KIT-CARD"
    sequence(:sku) {|n| Settings.kit_card_product+"#{n}" }
    cost_center "kit-card"
    recurrent true
    stock 10
  end  

  factory :product_without_recurrent, class: Product do
    name "Kit kard"
    package "KIT-CARD"
    sequence(:sku) {|n| Settings.kit_card_product+"#{n}" }
    cost_center "kit-card"
    recurrent false
    stock 10
  end  
end