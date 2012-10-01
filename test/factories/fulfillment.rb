FactoryGirl.define do

  factory :fulfillment do
    product_sku "kit-card"
    assigned_at DateTime.now
    status 'not_processed'
  end

  factory :fulfillment_undeliverable_with_stock, class: Fulfillment do
    product_sku "Bracelet"
    assigned_at DateTime.now
    status 'undeliverable'
  end

  factory :fulfillment_undeliverable_without_stock, class: Fulfillment do
    product_sku "circlet"
    assigned_at DateTime.now
    status 'undeliverable'
  end

  factory :fulfillment_processing, class: Fulfillment do
    product_sku "kit-card"
    assigned_at DateTime.now
    status 'processing'
  end

  factory :fulfillment_processing_without_stock, class: Fulfillment do
    product_sku "circlet"
    assigned_at DateTime.now
    status 'processing'
  end
end