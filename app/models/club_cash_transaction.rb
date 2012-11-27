class ClubCashTransaction < ActiveRecord::Base
  belongs_to :member

  attr_accessible :amount, :description

  validates :amount, :presence => true, :numericality => true, :format => {:with => /^(\-)?\d*(.\d{0,2})?$/, :message => "Max amount of digits after comma is 2."}
  


  def error_to_s(delimiter = ". ")
    self.errors.collect {|attr, message| "#{attr}: #{message}" }.join(delimiter)
  end

end