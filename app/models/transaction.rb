class Transaction < ActiveRecord::Base
  belongs_to :member
  belongs_to :payment_gateway_configuration
  belongs_to :decline_strategy

  # attr_accessible :title, :body

end
