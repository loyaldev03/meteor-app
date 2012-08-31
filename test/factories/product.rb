FactoryGirl.define do

  factory :product do
    name "Bracelet"
    sku "Bracelet"
    stock 10
  end

  factory :product_without_stock, class: Product do
    name "Circlet"
    sku "circlet"
    stock 0
  end  	

  factory :product_with_recurrent, class: Product do
    name "Kit kard"
    sku "kit-kard"
    recurrent true
    stock 0
  end  

end