class Domain < ActiveRecord::Base
  # has_many :users
  belongs_to :partner
  belongs_to :club

  attr_accessible :data_rights, :deleted_at, :description, :hosted, :partner, :url, :club_id
  
  # this validation is comented because it does not works the nested form
  # of partner. TODO: can we add this validation without problems?
  # validates :partner, :presence => true 
  validates :url, :presence => { :message => "Cant be blank." },
                  :uniqueness => { :message => "Has already been taken" }, 
                  :format =>  /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
  acts_as_paranoid

  before_destroy :verify_if_is_last_domain

  def self.datatable_columns
    ['id', 'url', 'description', 'data_rights', 'hosted', 'created_at' ]
  end

  def verify_if_is_last_domain
  	@domains = Domain.where(:partner_id =>partner_id)
      if @domains.count == 1
        errors.add :base, :error => "Cannot destroy last domain. Partner must have at least one domain."
        false
      end
  end
end
