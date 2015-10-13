class ClubCashTransaction < ActiveRecord::Base
  belongs_to :user

  attr_accessible :amount, :description

  validates :amount, :presence => true, :numericality => true, :format => {:with => /^(\-)?\d*(.\d{0,2})?$/, :message => "Max amount of digits after comma is 2."}

  def error_to_s(delimiter = ". ")
    self.errors.collect {|attr, message| "#{attr}: #{message}" }.join(delimiter)
  end

  def errors_merged(user)
    errors = self.errors.to_hash
    errors.merge!(user: user.errors.to_hash) unless user.errors.empty?
    errors
  end

  def self.datatable_columns
    ['created_at', 'description', 'amount', 'id' ]
  end
end
