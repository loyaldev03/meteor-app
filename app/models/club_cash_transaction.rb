class ClubCashTransaction < ActiveRecord::Base
  belongs_to :member

  attr_accessible :amount, :description

  validates :amount, :presence => true

end