class CampaignProduct < ActiveRecord::Base
  belongs_to :campaign, counter_cache: :products_count
  belongs_to :product
  acts_as_list scope: :campaign, add_new_at: :bottom

  before_validation :set_product_label
  before_create :check_campaign_products_limit
  validates_uniqueness_of :product_id, scope: :campaign_id

  private

  def set_product_label
    self.label = product.sanitized_name unless label.present?
  end

  # Using this method instead of validates_associated and validates_length_of since it is not working properly when combining it with acts_as_list.
  def check_campaign_products_limit
    if self.campaign.campaign_products.count >= Campaign::MAX_PRODUCTS_ALLOWED
      raise CampaignMaxProductsException.new("Campaign has too many products. Maximum allowed is #{Campaign::MAX_PRODUCTS_ALLOWED}.")
    end
  end
end
