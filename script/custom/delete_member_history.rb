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

class Member < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "members" 
  self.primary_key = 'uuid'
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

class MemberNote < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "member_notes" 
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

class MemberPreference < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "member_preferences"
end

###################################################
##### METHODS #####################################

def delete_operations(member)
  tz = Time.now.utc
  operations = Operation.find_all_by_member_id(member.id)
  if operations.kind_of?(Array)
    operations.each do |operation|
      operation.delete
    end
  else
    operations.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member's operations."
end

def delete_member_notes(member)
  tz = Time.now.utc
  member_notes = MemberNote.find_all_by_member_id(member.id)
  member_notes.each do |member_note|
    member_note.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member notes."
end

def delete_member_preferences(member)
  tz = Time.now.utc
  member_preferences = MemberPreference.find_all_by_member_id(member.id)
  member_preferences.each do |member_preference|
    member_preference.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member preferences."
end

def delete_credit_cards(member)
  tz = Time.now.utc
  credit_cards = CreditCard.find_all_by_member_id(member.id)
  credit_cards.each do |credit_card|
    credit_card.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member's credit cards."
end

def delete_transactions(member)
  tz = Time.now.utc
  transactions = Transaction.find_all_by_member_id(member.id)
  transactions.each do |transaction|
    transaction.delete rescue nil
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member's transactions."
end

def delete_fulfillments(member)
  tz = Time.now.utc
  fulfillments = Fulfillment.find_all_by_member_id(member.id)
  fulfillments.each do |fulfillment|
    fulfillment.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member fulfillments."
end

def delete_communications(member)
  tz = Time.now.utc
  communications = Communication.find_all_by_member_id(member.id)
  communications.each do |communication|
    communication.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member communications."
end

def delete_club_cash_transactions(member)
  tz = Time.now.utc
  ccts = ClubCashTransaction.find_all_by_member_id(member.id)
  ccts.each do |cct|
    cct.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member's club cash transactions."
end

def delete_memberships(member)
  tz = Time.now.utc
  memberships = Membership.find_all_by_member_id(member.id)
  memberships.each do |membership|
    membership.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member memberships."
end

def delete_enrollment_infos(member)
  tz = Time.now.utc
  enrollment_infos = EnrollmentInfo.find_all_by_member_id(member.id)
  enrollment_infos.each do |enrollment_info|
    enrollment_info.delete
  end
  @log.info "    ... took #{Time.now.utc - tz} to delete member enrollment infos."
end

def delete_member(member)
  tz = Time.now.utc
  member.delete
  @log.info "    ... took #{Time.now.utc - tz} to delete member information."
end

def delete_functions(member)
  delete_operations(member)
  delete_member_notes(member)
  delete_member_preferences(member)
  delete_enrollment_infos(member)
  delete_credit_cards(member)
  delete_memberships(member)
  delete_transactions(member)
  delete_fulfillments(member)
  delete_club_cash_transactions(member)
  delete_communications(member)
  delete_member(member)
end

def init(id)
  start_time = Time.now.utc 
  member =  Member.find(id)
  @log.info "Deleting member #{member.first_name} record."
  delete_functions(member)
  @log.info "    ... took #{Time.now.utc - start_time} to delete member's history."
end

member_id = ARGV[0]
init(member_id)

