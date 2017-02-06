module Products
  class AlertOnLowStockJob < ActiveJob::Base
    queue_as :products
  
    def perform(product_id:)
      product = Product.find(product_id)
      title = "Low Product Stock (#{product.sku})"
      description = "--- **WARNING**: #{product.name} (#{product.sku}) stock is **#{product.stock}** unit(s) --"
      story_type = 'chore'
      Auditory.create_user_story(description, title, PIVOTAL_TRACKER_MARKETING_PROJECT, story_type)
      product.update_column(:low_stock_alerted, true)
    end
  end
end