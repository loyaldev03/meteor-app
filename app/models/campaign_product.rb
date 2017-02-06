class CampaignProduct < ActiveRecord::Base
  belongs_to :campaign, counter_cache: :products_count
  belongs_to :product

  before_validation :set_product_label

  validates_uniqueness_of :product_id, scope: :campaign_id
  validates_associated :campaign, message: lambda { |_class_obj, obj| obj[:value].errors.full_messages.join(",") }

  private

  def set_product_label
    self.label = product.name unless label.present?
  end
end
