#
# api_type column should have Drupal::Member or Wordpress::Member
#
class Club < ActiveRecord::Base
  belongs_to :partner
  has_many :domains
  has_many :terms_of_memberships
  has_many :members
  has_many :payment_gateway_configurations
  has_many :member_group_types

  attr_accessible :description, :name, :logo

  acts_as_paranoid

  after_create :add_default_member_groups

  validates :partner_id, :presence => true
  validates :name, :presence => true, :uniqueness => true

  has_attached_file :logo, :path => ":rails_root/public/system/:attachment/:id/:style/:filename", 
                           :url => "/system/:attachment/:id/:style/:filename",
                           :styles => { :header => "50x50#", :thumb => "100x100#", :small  => "150x150>" }

  def full_name
    [ partner.name, name ].join(' ')
  end

  private
    def add_default_member_groups
      ['VIP', 'Celebrity', 'Notable'].each do |name|
        m = MemberGroupType.new
        m.name= name
        m.club_id = self.id
        m.save
      end
    end

end
