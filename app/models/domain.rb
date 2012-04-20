class Domain < ActiveRecord::Base
  belongs_to :partner
  belongs_to :club
  has_many :users

  attr_accessible :data_rights, :deleted_at, :description, :hosted, :partner, :url, :club_id
  
  # this validation is comented because it does not works the nested form
  # of partner. TODO: can we add this validation without problems?
  # validates :partner, :presence => true 
  validates :url, :presence => true, :uniqueness => true

  acts_as_paranoid

  before_destroy :veriby_if_is_last_domain

  def veriby_if_is_last_domain
  	@domains = Domain.where(:partner_id =>partner_id)
      if @domains.count == 1
        errors.add :base, :error => "Cannot destroy last domain. Partner must have at least one domain."
        false
      end
  end
end
