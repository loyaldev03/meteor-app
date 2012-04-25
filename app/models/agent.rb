class Agent < ActiveRecord::Base
  # Include default devise modules. Others available are:
  #  :omniauthable
  devise :database_authenticatable, :registerable, :lockable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, 
         :encryptable, :token_authenticatable

  acts_as_paranoid

  has_many :created_members, :class_name => 'Member'
  has_many :operations

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :login, :first_name, :last_name

  validates :username, :uniqueness => true
  validates :username, :email, :presence => :true, :length => { :maximum => 20, :too_long => 'Pick a shorter username' }


  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.strip.downcase }]).first
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
