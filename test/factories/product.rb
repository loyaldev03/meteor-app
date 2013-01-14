FactoryGirl.define do

  factory :product do
    name "Bracelet"
    package "NCARFLAG"
    sku "Bracelet"
    stock 10
    weight 5
  end

  factory :product_without_stock_and_not_recurrent, class: Product do
    name "Circlet"
    package "NCARFLAG"
    sku "circlet"
    stock 0
    recurrent false
  end  	

  factory :product_without_stock_and_recurrent, class: Product do
    name "Kit kard"
    package "NCARFLAG"
    sku "kit-kard"
    recurrent true
    stock 0
  end 

  factory :product_with_recurrent, class: Product do
    name "Kit kard"
    package "KIT-CARD"
    sku "kit-kard"
    recurrent true
    stock 10
  end  

  factory :product_without_recurrent, class: Product do
    name "Kit kard"
    package "KIT-CARD"
    sku "kit-kard"
    recurrent false
    stock 10
  end  
end