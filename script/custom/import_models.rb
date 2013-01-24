# 1- Get access to phoenix, billing_component, customer_services and prospect databases
# UPDATE prospectcomponente.prospects set imported_at = NULL where imported_at IS NOT NULL
# UPDATE billing_component.members set imported_at = NULL where imported_at IS NOT NULL
# UPDATE notes set imported_at = NULL where imported_at IS NOT NULL
# UPDATE operations set imported_at = NULL where imported_at IS NOT NULL
# 2- Import new prospects into phoenix
#     ruby script/custom/import_prospects.rb  
# 3- Update members already imported and Load new members 
#     ruby script/custom/import_members.rb  
# 4- Import operations.
#     ruby script/custom/import_operations.rb  
# 5- Import member notes.
#     ruby script/custom/import_member_notes.rb  
# 6- Import transactions.
#     ruby script/custom/import_transactions.rb  
#
#
# 3- set campaign_id on every membership authorization, to get the amount. 
#   UPDATE onmc_billing.membership_authorizations SET campaign_id = 
#      (SELECT campaign_id FROM onmc_billing.members WHERE id =  onmc_billing.membership_authorizations.member_id) WHERE
#       onmc_billing.membership_authorizations campaign_id IS NULL;

require 'rubygems'
require 'rails'
require 'active_record'
require 'uuidtools'
require 'attr_encrypted'
require 'settingslogic'

CLUB = 1 # ONMC
DEFAULT_CREATED_BY = 1 # batch
PAYMENT_GW_CONFIGURATION_LITLE = 2 
PAYMENT_GW_CONFIGURATION_MES = 3
TEST = false # if true email will be replaced with a fake one
USE_PROD_DB = true
SITE_ID = 2010001547 # lyris site id
MEMBER_GROUP_TYPE = 4 # MemberGroupType.new :club_id => CLUB, :name => "Chapters"
TIMEZONE = 'Eastern Time (US & Canada)'

CREDIT_CARD_NULL = "a"
USE_MEMBER_LIST = true


if USE_PROD_DB
#  puts "by default do not continue. Uncomment this line if you want to run script. \n\t check configuration above." 
#  exit
end

unless USE_PROD_DB
  ActiveRecord::Base.configurations["phoenix"] = { 
    :adapter => "mysql2",
    :database => "sac_platform_development",
    :host => "127.0.0.1",
    :username => "root",
    :password => "" 
  }

  ActiveRecord::Base.configurations["billing"] = { 
    :adapter => "mysql2",
    :database => "onmc_billing",
    :host => "127.0.0.1",
    :username => "root",
    :password => "" 
  }

  ActiveRecord::Base.configurations["customer_services"] = { 
    :adapter => "mysql2",
    :database => "onmc_customer_service",
    :host => "127.0.0.1",
    :username => "root",
    :password => "" 
  }

  ActiveRecord::Base.configurations["prospect"] = { 
    :adapter => "mysql2",
    :database => "onmc_prospects",
    :host => "127.0.0.1",
    :username => "root",
    :password => "" 
  }
else
  # PRODUCTION !!!!!!!!!!!!!!!!
  ActiveRecord::Base.configurations["phoenix"] = { 
    :adapter => "mysql2",
    :database => "sac_production",
    :host => "10.6.0.58",
    :username => "root",
    :password => 'pH03n[xk1{{s', 
    :port => 3306 
  }

  ActiveRecord::Base.configurations["billing"] = { 
    :adapter => "mysql2",
    :database => "billingcomponent_production",
    :host => "10.6.0.6",
    :username => "root2",
    :password => "f4c0n911",
    :port => 3306
  }

  ActiveRecord::Base.configurations["customer_services"] = { 
    :adapter => "mysql2",
    :database => "customerservice3",
    :host => "10.6.0.6",
    :username => "root2",
    :password => "f4c0n911",
    :port => 3308
  }

  ActiveRecord::Base.configurations["prospect"] = { 
    :adapter => "mysql2",
    :database => "prospectcomponent",
    :host => "10.6.0.6",
    :username => "root2",
    :password => "f4c0n911",
    :port => 3306
  }
end


class ProspectProspect < ActiveRecord::Base
  establish_connection "prospect" 
  self.table_name = "prospects" 
  self.record_timestamps = false

  def email_to_import
    TEST ? "test#{member.id}@xagax.com" : email
  end  
end

class PhoenixMember < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "members" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

  def terms_of_membership_id
    PhoenixMembership.find_by_member_id(self.id).terms_of_membership_id rescue nil
  end

  def phone_number=(phone)
    return if phone.nil?
    p = phone.gsub(/[\s~\(\/\-=\)"\_\.\[\]+]/, '')
    p = p.split('ext')[0] if p.split('ext').size == 2

    if p.size < 6 || p.include?('@') || !p.match(/^[a-z]/i).nil? || p.include?('SOAP::Mapping')
    elsif p.size == 7  || p.size == 8 || p.size == 6
      self.phone_country_code = '1'
      self.phone_local_number = p
    elsif p.size >= 20
      self.phone_country_code = '1'
      self.phone_area_code = p[0..2]
      self.phone_local_number = p[3..9]
    elsif p.size == 10 || p.size == 9
      self.phone_country_code = '1'
      self.phone_area_code = p[0..2]
      self.phone_local_number = p[3..-1]
    elsif p.size == 11
      self.phone_country_code = p[0..0]
      self.phone_area_code = p[1..3]
      self.phone_local_number = p[4..-1]
    elsif p.size == 12
      self.phone_country_code = p[0..1]
      self.phone_area_code = p[2..4]
      self.phone_local_number = p[5..-1]
    elsif p.size == 13
      self.phone_country_code = p[0..1]
      self.phone_area_code = p[2..5]
      self.phone_local_number = p[6..-1]
    elsif 
      num = p.split('ext')[0]
      self.phone_country_code = p[0..1]
      self.phone_area_code = p[2..5]
      self.phone_local_number = p[6..-1]
    else
      #raise "Dont know how to parse -#{p}-"
    end
  end
end

class PhoenixProspect < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "prospects" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

# 3304940833ext412

  def phone_number=(phone)
    return if phone.nil?
    p = phone.gsub(/[\s~\(\/\-=\)"\_\.\[\]+]/, '')
    p = p.split('ext')[0] if p.split('ext').size == 2

    if p.size < 6 || p.include?('@') || !p.match(/^[a-z]/i).nil? || p.include?('SOAP::Mapping')
    elsif p.size == 7  || p.size == 8 || p.size == 6
      self.phone_country_code = '1'
      self.phone_local_number = p
    elsif p.size >= 20
      self.phone_country_code = '1'
      self.phone_area_code = p[0..2]
      self.phone_local_number = p[3..9]
    elsif p.size == 10 || p.size == 9
      self.phone_country_code = '1'
      self.phone_area_code = p[0..2]
      self.phone_local_number = p[3..-1]
    elsif p.size == 11
      self.phone_country_code = p[0..0]
      self.phone_area_code = p[1..3]
      self.phone_local_number = p[4..-1]
    elsif p.size == 12
      self.phone_country_code = p[0..1]
      self.phone_area_code = p[2..4]
      self.phone_local_number = p[5..-1]
    elsif p.size == 13
      self.phone_country_code = p[0..1]
      self.phone_area_code = p[2..5]
      self.phone_local_number = p[6..-1]
    elsif 
      num = p.split('ext')[0]
      self.phone_country_code = p[0..1]
      self.phone_area_code = p[2..5]
      self.phone_local_number = p[6..-1]
    else
      raise "Dont know how to parse -#{p}-"
    end
  end
end
class PhoenixCreditCard < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "credit_cards"
  attr_encrypted :number, :key => 'reibel3y5estrada8', :encode => true, :algorithm => 'bf'
end
class PhoenixOperation < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "operations" 
end
class PhoenixClubCashTransaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "club_cash_transactions" 
end
class PhoenixEnrollmentInfo < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "enrollment_infos" 
end
class PhoenixTransaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "transactions" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

  def set_payment_gateway_configuration(gateway)
    if gateway == 'litle'
      pgc = PhoenixPGC.find(PAYMENT_GW_CONFIGURATION_LITLE)
    else
      pgc = PhoenixPGC.find(PAYMENT_GW_CONFIGURATION_MES)
    end
    self.payment_gateway_configuration_id = pgc.id
    self.report_group = pgc.report_group
    self.merchant_key = pgc.merchant_key
    self.login = pgc.login
    self.password = pgc.password
    self.mode = pgc.mode
    self.descriptor_name = pgc.descriptor_name
    self.descriptor_phone = pgc.descriptor_phone
    self.order_mark = pgc.order_mark
    self.gateway = pgc.gateway
  end  
end
class PhoenixPGC < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "payment_gateway_configurations" 
end
class PhoenixMemberNote < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "member_notes" 
end
class PhoenixEnumeration < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "enumerations" 
end
class DispositionType < PhoenixEnumeration
end
class CommunicationType < PhoenixEnumeration
end
class PhoenixAgent < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "agents" 
end
class PhoenixFulfillment < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "fulfillments"
end
class PhoenixTermsOfMembership < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "terms_of_memberships" 
end
class PhoenixEmailTemplate < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "email_templates" 
end
class PhoenixMembership < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "memberships" 
end

class Settings < Settingslogic
  source "application.yml"
  namespace Rails.env
end




class BillingMember < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "members"
  self.record_timestamps = false

  def email_to_import
    TEST ? "test#{member.id}@xagax.com" : email
  end
end
class BillingCampaign < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "campaigns" 
  self.record_timestamps = false
  def is_joint
    joint == 'n' ? false : true
  end
end
class BillingEnrollmentAuthorizationResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_auth_responses" 
  self.record_timestamps = false
  def phoenix_gateway
    gateway == 'mes' ? gateway : 'litle'
  end
  def authorization
    BillingEnrollmentAuthorization.find_by_id(self.authorization_id)
  end
  def invoice_number(a)
    "#{self.created_at.to_date}-#{a.member_id}"
  end
  def member
    PhoenixMember.find_by_visible_id_and_club_id(authorization.member_id, CLUB)
  end
  def amount
    phoenix_amount
  end
end
class BillingEnrollmentAuthorization < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_authorizations" 
  self.record_timestamps = false
end
class BillingMembershipAuthorizationResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_auth_responses" 
  self.record_timestamps = false
  def phoenix_gateway
    gateway == 'mes' ? gateway : 'litle'
  end
  def authorization
    BillingMembershipAuthorization.find_by_id(self.authorization_id)
  end
  def member
    PhoenixMember.find_by_visible_id_and_club_id(authorization.member_id, CLUB)
  end
  def billing_member
    BillingMember.find_by_id(authorization.member_id)
  end
  def invoice_number(a)
    "#{self.created_at.to_date}-#{a.member_id}"
  end
  def amount
    phoenix_amount
  end
end
class BillingMembershipAuthorization < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_authorizations" 
  self.record_timestamps = false
end
class BillingChargeback < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "chargebacks" 
  self.record_timestamps = false
  def phoenix_gateway
    gateway == 'mes' ? gateway : 'litle'
  end
end



class CustomerServicesOperations < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "operations"
  self.record_timestamps = false
end
class CustomerServicesNotes < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "notes"
  self.record_timestamps = false
end
class CustomerServicesNoteType < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "note_types" 
  self.record_timestamps = false
end
class CustomerServicesCommunication < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "communications" 
  self.record_timestamps = false
end
class CustomerServicesUser < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "users" 
  self.inheritance_column = false
  self.record_timestamps = false
end



########################################################################################################
###########################   FUNCTIONS             ####################################################
########################################################################################################

def get_agent(author = 999)
  if author == 999
    DEFAULT_CREATED_BY
  else
    @users ||= CustomerServicesUser.all
    u = @users.select {|x| x.id == author }
    if u.empty?
      DEFAULT_CREATED_BY
    else
      a = PhoenixAgent.find_by_username(u[0].login)
      if a.nil?
        a = PhoenixAgent.new :username => u[0].login, :first_name => u[0].firstname, :last_name => u[0].lastname, 
            :email => u[0].mail
        a.save!
      end
      a.id
    end
  end
end

def add_operation(operation_date, object_class, object_id, description, operation_type, created_at = Time.now.utc, updated_at = Time.now.utc, author = 999)
  o = PhoenixOperation.new :operation_date => operation_date, :description => description, 
      :operation_type => (operation_type || Settings.operation_types.others)
  o.created_by_id = get_agent
  o.created_at = created_at
  unless object_class.nil?
    o.resource_type = object_class
    o.resource_id = object_id
  end
  o.updated_at = updated_at
  o.member_id = @member.uuid
  o.save!
end

def get_campaign_and_tom_id(cid)
  @campaign = BillingCampaign.find_by_id(cid)
  @tom_id = nil
  unless @campaign.nil?
    if @campaign.phoenix_tom_id.nil?
      @tom_id = get_terms_of_membership_id(cid)
      @campaign = BillingCampaign.find_by_id(cid)
    else
      @tom_id = @campaign.phoenix_tom_id
    end
  end
end

def set_last_billing_date_on_credit_card(member, transaction_date)
  cc = PhoenixCreditCard.find_by_active_and_member_id true, member.id
  if cc and (cc.last_successful_bill_date.nil? or cc.last_successful_bill_date < transaction_date)
    cc.update_attribute :last_successful_bill_date, transaction_date
  end
end

# If we store data in UTC, dates are converted to time using 00:00 am. So in CLT it will be the day before
def convert_from_date_to_time(x)
  if x.class == Date
    x.to_time + 12.hours
  elsif x.class == DateTime || x.class == Time
    x
  end
end

require 'import_communications'
