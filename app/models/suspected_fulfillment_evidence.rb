class SuspectedFulfillmentEvidence < ActiveRecord::Base
  belongs_to :fulfillment
  belongs_to :matched_fulfillment, class_name: 'Fulfillment', foreign_key: 'matched_fulfillment_id'

  validates :fulfillment_id, :matched_fulfillment_id, :presence => true

  before_create :set_match_age

  private
    def set_match_age
      self.match_age = (fulfillment.created_at.to_date - matched_fulfillment.created_at.to_date).to_i
      true
    end
end