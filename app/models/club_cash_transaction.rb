class ClubCashTransaction < ActiveRecord::Base
  belongs_to :member

  attr_accessible :amount, :description

  validates :amount, :presence => true, :numericality => {:only_integer => true}
  
  def error_to_s(delimiter = ". ")
    self.errors.collect {|attr, message| "#{attr}: #{message}" }.join(delimiter)
  end

end