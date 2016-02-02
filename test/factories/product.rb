FactoryGirl.define do
  factory :product do
    name Settings.others_product.capitalize
    sku Settings.others_product
    package Settings.others_product
    cost_center Settings.others_product.capitalize
    stock 10
    weight 5

    factory :random_product do
      sequence(:sku) {|n| Settings.others_product+"#{n}" }
      sequence(:name) {|n| (Settings.others_product+"#{n}").capitalize }
    end

    factory :product_without_stock_and_not_recurrent do
      sequence(:sku) {|n| Settings.others_product+"#{n}" }
      sequence(:name) {|n| (Settings.others_product+"#{n}").capitalize }
      stock 0
      recurrent false
    end

    factory :product_without_stock_and_recurrent do
      sequence(:sku) {|n| Settings.others_product+"#{n}" }
      sequence(:name) {|n| (Settings.others_product+"#{n}").capitalize }
      recurrent true
      stock 0
    end

    factory :product_without_stock_and_not_backorder do
      sequence(:sku) {|n| Settings.others_product+"#{n}" }
      sequence(:name) {|n| (Settings.others_product+"#{n}").capitalize }
      stock 0
      allow_backorder false
    end

    factory :product_with_recurrent do
      sequence(:sku) {|n| Settings.others_product+"#{n}" }
      sequence(:name) {|n| (Settings.others_product+"#{n}").capitalize }
      recurrent true
    end

    factory :product_without_recurrent do
      sequence(:sku) {|n| Settings.others_product+"#{n}" }
      sequence(:name) {|n| (Settings.others_product+"#{n}").capitalize }
      recurrent false
    end
  end
end