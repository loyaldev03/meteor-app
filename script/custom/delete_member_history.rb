#!/bin/ruby
require 'rubygems'
require 'rails'
require 'active_record' 

@log = Logger.new('delet_member.log', 10, 1024000)
ActiveRecord::Base.logger = @log

ActiveRecord::Base.configurations["phoenix"] = {
  :adapter => "mysql2",
  :database => "sac_platform_development",
  :host => "127.0.0.1",
  :username => "root",
  :password => "" 
}

###################################################
##### CLASES ######################################

class User < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "users" 
  self.primary_key = 'id'
end

class Membership < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "memberships" 
end

class Operation < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "operations" 
end

class ClubCashTransaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "club_cash_transactions" 
end

class EnrollmentInfo < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "enrollment_infos" 
end

class UserNote < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "user_notes" 
end

class CreditCard < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "credit_cards"
end

class Transaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "transactions"
end

class Fulfillment < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "fulfillments"
end

class Communication < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "communications"
end

class UserPreference < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "user_preferences"
end

###################################################
##### METHODS #####################################

def delete_operations(user)
  tz = Time.now.utc
  Operation.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user's operations."
end

def delete_user_notes(user)
  tz = Time.now.utc
  UserNote.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user notes."
end

def delete_user_preferences(user)
  tz = Time.now.utc
  UserPreference.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user preferences."
end

def delete_credit_cards(user)
  tz = Time.now.utc
  CreditCard.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user's credit cards."
end

def delete_transactions(user)
  tz = Time.now.utc
  Transaction.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user's transactions."
end

def delete_fulfillments(user)
  tz = Time.now.utc
  Fulfillment.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user fulfillments."
end

def delete_communications(user)
  tz = Time.now.utc
  Communication.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user communications."
end

def delete_club_cash_transactions(user)
  tz = Time.now.utc
  ClubCashTransaction.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user's club cash transactions."
end

def delete_memberships(user)
  tz = Time.now.utc
  Membership.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user memberships."
end

def delete_enrollment_infos(user)
  tz = Time.now.utc
  EnrollmentInfo.delete_all(["user_id = ?", user.id])
  @log.info "    ... took #{Time.now.utc - tz} to delete user enrollment infos."
end

def delete_user(user)
  tz = Time.now.utc
  user.delete
  @log.info "    ... took #{Time.now.utc - tz} to delete user information."
end

def delete_functions(user)
  delete_operations(user)
  delete_user_notes(user)
  delete_user_preferences(user)
  delete_enrollment_infos(user)
  delete_credit_cards(user)
  delete_memberships(user)
  delete_transactions(user)
  delete_fulfillments(user)
  delete_club_cash_transactions(user)
  delete_communications(user)
  delete_user(user)
end

def init(id)
  start_time = Time.now.utc 
  user =  User.find(id)
  @log.info "Deleting user #{user.first_name} record."
  delete_functions(user)
  @log.info "    ... took #{Time.now.utc - start_time} to delete user's history."
end

user_id = ARGV[0]
init(user_id)

