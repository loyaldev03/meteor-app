FactoryBot.define do
  factory :fulfillment do
    product_sku { Settings.others_product }
    assigned_at { Time.now }
    status { 'not_processed' }
  end

  factory :fulfillment_bad_address_with_stock, class: Fulfillment do
    product_sku { 'Bracelet' }
    assigned_at { Time.now }
    status { 'bad_address' }
  end

  factory :fulfillment_bad_address_without_stock, class: Fulfillment do
    product_sku { 'circlet' }
    assigned_at { Time.now }
    status { 'bad_address' }
  end

  factory :fulfillment_processing, class: Fulfillment do
    product_sku { 'kit-card' }
    assigned_at { Time.now }
    status { 'processing' }
  end

  factory :fulfillment_processing_without_stock, class: Fulfillment do
    product_sku { 'circlet' }
    assigned_at { Time.now }
    status { 'processing' }
  end
end
