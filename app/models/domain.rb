class Domain < ActiveRecord::Base
  # has_many :users
  belongs_to :partner
  belongs_to :club
  acts_as_paranoid

  # this validation is comented because it does not works the nested form
  # of partner. TODO: can we add this validation without problems?
  # validates :partner, :presence => true 
  validates :url, presence: { message: "can't be blank." },
                  format: /(^$)|(^(http|https):\/\/([\w]+:\w+@)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,
                  uniqueness: { scope: :deleted_at }

  before_destroy :verify_if_is_last_domain, :check_association

  def self.datatable_columns
    ['id', 'url', 'description', 'data_rights', 'hosted' ]
  end

  def verify_if_is_last_domain
  	@domains = Domain.where(partner_id: partner_id)
    if @domains.count == 1
      errors.add :base, error: "Cannot destroy last domain. Partner must have at least one domain."
      false
    end
  end

  def check_association
    club = Club.find_by(drupal_domain_id: self.id)
    unless club.nil?
      errors.add :base, error: "Cannot destroy this domain. It is set as drupal domain for club #{club.name}. Please unset this before proceding to delete this domain."
      false
    end
  end
end
