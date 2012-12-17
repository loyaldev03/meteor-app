class Agent < ActiveRecord::Base
  # Include default devise modules. Others available are:
  #  :omniauthable

  # :confirmable, :registerable

  devise :database_authenticatable, :lockable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable, 
         :encryptable, :token_authenticatable

  easy_roles :roles
  ROLES = %W(admin api representative supervisor agency)

  acts_as_paranoid
  validates_as_paranoid

  has_many :created_members, :class_name => 'Membership'
  has_many :operations

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :login, :first_name, 
    :last_name, :roles, :club_roles_attributes

  validates_uniqueness_of_without_deleted :username
  validates :username, :presence => true, :length => { :maximum => 20, :too_long => 'Pick a shorter username' }


  before_save :ensure_authentication_token

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.strip.downcase }]).first
  end

  def self.datatable_columns
    [ 'id', 'email', 'username', 'created_at' ]
  end

  has_many :club_roles
  has_many :clubs, 
    through: :club_roles,
    uniq: true
  accepts_nested_attributes_for :club_roles,
    allow_destroy: true

  def has_role_with_club?(role, club_id = nil)
    club_id = club_id.to_param
    self.has_role_without_club?(role) || club_id && self.role_for(role, club_id).present?
  end
  alias_method_chain :has_role?, :club

  def role_for(role, club)
    self.club_roles.where(role: role, club_id: club).first
  end

  def has_global_role?
    !self.roles.empty?
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

  protected

   # Attempt to find a user by it's email. If a record is found, send new
   # password instructions to it. If not user is found, returns a new user
   # with an email not found error.
   def self.send_reset_password_instructions(attributes={})
     recoverable = find_recoverable_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
     recoverable.send_reset_password_instructions if recoverable.persisted?
     recoverable
   end 

   def self.find_recoverable_or_initialize_with_errors(required_attributes, attributes, error=:invalid)
     (case_insensitive_keys || []).each { |k| attributes[k].try(:downcase!) }

     attributes = attributes.slice(*required_attributes)
     attributes.delete_if { |key, value| value.blank? }

     if attributes.size == required_attributes.size
       if attributes.has_key?(:login)
          login = attributes[:login]
          record = find_record(login)
       else  
         record = where(attributes).first
       end  
     end  

     unless record
       record = new

       required_attributes.each do |key|
         value = attributes[key]
         record.send("#{key}=", value)
         record.errors.add(key, value.present? ? error : :blank)
       end  
     end  
     record
   end

   def self.find_record(login)
      where(["username = :value OR email = :value", { :value => login }]).first
   end

end
