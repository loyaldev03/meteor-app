class Agent < ActiveRecord::Base
  # Include default devise modules. Others available are:
  #  :omniauthable

  # :confirmable, :registerable

  devise :database_authenticatable, :lockable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable, 
         :encryptable, 
         :async

  ROLES = %W(admin api representative supervisor agency fulfillment_managment)

  acts_as_paranoid

  has_many :created_members, class_name: 'Membership'
  has_many :operations
  has_many :fulfillment_files
  has_many :terms_of_memberships

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  validates :username, presence: true, 
                       length: { maximum: 20, too_long: 'Pick a shorter username' },
                       uniqueness: { scope: :deleted_at }

  def self.datatable_columns
    [ 'id', 'email', 'username', 'created_at' ]
  end

  has_many :club_roles
  has_many :clubs, -> {uniq}, through: :club_roles

  def which_is_the_role_for_this_club?(club_id)
    self.club_roles.where(club_id: club_id).first
  end

  def has_role?(role)
    self.roles == role
  end

  def add_role(role)
    has_role?(role) ? false : self.roles = role
  end

  def has_role_with_club?(role, club_id = nil)
    # logger.debug "role: #{role} club_id: #{club_id}        #{self.has_role_without_club?(role) || club_id && self.role_for(role, club_id).present?}"
    club_id = club_id.to_param
    self.has_role_without_club?(role) || club_id && self.role_for(role, club_id).present?
  end
  alias_method_chain :has_role?, :club

  def is_admin?
    if @is_admin.nil?
      @is_admin = false
      @is_admin = true if self.has_role?("admin")
      unless @is_admin 
        self.club_roles.each do |club_role|
          @is_admin = true if club_role.role == "admin"
        end
      end
    end
    @is_admin
  end

  def clubs_related_id_list(role=nil)
    if role 
      club_roles.where("role = ?", role).collect(&:club_id)
    else
      club_roles.collect(&:club_id)
    end
  end

  def has_role_or_has_club_role_where_can?(action, model, clubs_id_list = nil)
    if self.has_global_role?
      return true if can? action, model
    else
      clubs_id_list ||= self.clubs_related_id_list
      clubs_id_list.each do |club_id|
        return true if can? action, model, club_id
      end
    end
    false 
  end

  def role_for(role, club)
    self.club_roles.where(role: role, club_id: club).first
  end

  def has_global_role?
    !self.roles.blank?
  end

  def has_club_roles?
    !self.clubs.empty?
  end

  def add_role_with_club(role, club = nil)
    if club.present? 
      if self.role_for(role, club).blank?
        self.club_roles.create(role: role, club_id: club.to_param)
      end
    else
      self.add_role_without_club(role)
    end
  end
  alias_method_chain :add_role, :club

  def can?(*args)
    @ability = Ability.new(self, args[2])
    @ability.can?(*args)
  end

  def club_roles_without_api
    self.club_roles.select(:club_id).where("role != 'api'").collect &:club_id
  end

  def set_club_roles(club_roles_info)
    club_roles_info.each do |index, club_role|
      self.club_roles << ClubRole.create(role: club_role[:role], club_id: club_role[:club_id]) 
    end
  end

  def delete_club_roles(club_roles_id)
    club_roles_id.each do |club_role_id|
      ClubRole.delete(club_role_id)
    end
  end

  def can_agent_by_role_delete_club_role(club_role)
    self.has_club_roles? and ClubRole.where("agent_id = ? and club_id in (?)", club_role.agent_id, self.clubs_related_id_list("admin")).count == 1
  end


  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }]).first
    else
      where(conditions.to_h).first
    end
  end

end
