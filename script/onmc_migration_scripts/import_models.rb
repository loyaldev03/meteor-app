# 1- Get access to phoenix, billing_component, customer_services and prospect databases
# Devel database
# update onmc_billing.members set imported_at = NULL where imported_at IS NOT NULL;
# update onmc_billing.chargebacks set imported_at = NULL where imported_at IS NOT NULL;
# update onmc_billing.enrollment_auth_responses set imported_at = NULL where imported_at IS NOT NULL;
# update onmc_billing.membership_auth_responses set imported_at = NULL where imported_at IS NOT NULL;
# update onmc_customer_service.operations set imported_at = NULL where imported_at IS NOT NULL;
# update onmc_customer_service.notes set imported_at = NULL where imported_at IS NOT NULL;
# update onmc_prospects.prospects set imported_at = NULL where imported_at IS NOT NULL;
# production database
# update billingcomponent_production.members set imported_at = NULL where imported_at IS NOT NULL;
# update billingcomponent_production.chargebacks set imported_at = NULL where imported_at IS NOT NULL;
# update billingcomponent_production.enrollment_auth_responses set imported_at = NULL where imported_at IS NOT NULL;
# update billingcomponent_production.membership_auth_responses set imported_at = NULL where imported_at IS NOT NULL;
# update prospectcomponent.prospects set imported_at = NULL where imported_at IS NOT NULL;
# update customerservice3.operations set imported_at = NULL where imported_at IS NOT NULL;
# update customerservice3.notes set imported_at = NULL where imported_at IS NOT NULL;
# phoenix database
# use sac_production;
# truncate credit_cards;
# truncate enrollment_infos;
# truncate prospect;
# truncate fulfillments;
# truncate members;
# truncate memberships;
# truncate member_notes;
# truncate operations;
# truncate transactions;
#
# 1.1- Load toms (only once) => Done
#     ruby script/custom/import_load_toms.rb  
#
# 2- Update members already imported and Load new members 
#     ruby script/custom/import_members.rb  
#
# 3- Import operations.
#     ruby script/custom/import_operations.rb  
#
# 4- Import member notes.
#     ruby script/custom/import_member_notes.rb  
#
# 5- Import transactions.
#     ruby script/custom/import_transactions.rb  
#
# 6- Import .
#     ruby script/custom/import_migration_day.rb  
#
# 7- Import new prospects into phoenix (only if required)
#     ruby script/custom/import_prospects.rb  
#


require 'rubygems'
require 'rails'
require 'active_record'
require 'uuidtools'
require 'attr_encrypted'
require 'settingslogic'
require 'json'

CLUB = 1 # ONMC
DEFAULT_CREATED_BY = 1 # batch
PAYMENT_GW_CONFIGURATION_LITLE = 2 
PAYMENT_GW_CONFIGURATION_MES = 3
TEST_EMAIL = false # if true email will be replaced with a fake one
USE_PROD_DB = false
SITE_ID = 2010001547 # lyris site id
MEMBER_GROUP_TYPE = 19 # MemberGroupType.new :club_id => CLUB, :name => "Chapters"
TIMEZONE = 'Eastern Time (US & Canada)'

CREDIT_CARD_NULL = "a"
USE_MEMBER_LIST = false


if USE_PROD_DB
  #puts "by default do not continue. Uncomment this line if you want to run script. \n\t check configuration above." 
  #exit
end

unless USE_PROD_DB
  ActiveRecord::Base.configurations["phoenix"] = { 
    :adapter => "mysql2",
    :database => "sac_production",
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
    TEST_EMAIL ? "test#{member.id}@xagax.com" : email
  end  
end
class PhoenixMember < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "members" 
  self.record_timestamps = false

  def terms_of_membership_id
    PhoenixMembership.find_by_member_id(self.id).terms_of_membership_id rescue nil
  end
end
class PhoenixMemberPreference < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "member_preferences" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'
  self.record_timestamps = false
end
class PhoenixProspect < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "prospects" 
  self.primary_key = 'uuid'

  before_create 'self.id = UUIDTools::UUID.random_create.to_s'
  self.record_timestamps = false
end
class PhoenixCreditCard < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "credit_cards"
  attr_encrypted :number, :key => 'reibel3y5estrada8', :encode => true, :algorithm => 'bf'
  self.record_timestamps = false
end
class PhoenixOperation < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "operations"
  self.record_timestamps = false 
end
class PhoenixClubCashTransaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "club_cash_transactions" 
  self.record_timestamps = false
end
class PhoenixEnrollmentInfo < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "enrollment_infos" 
  self.record_timestamps = false
end
class PhoenixTransaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "transactions" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'
  self.record_timestamps = false

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
    self.gateway = pgc.gateway
  end  
end
class PhoenixPGC < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "payment_gateway_configurations" 
  self.record_timestamps = false
end
class PhoenixMemberNote < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "member_notes" 
  self.record_timestamps = false
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
  self.record_timestamps = false
end
class PhoenixEmailTemplate < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "email_templates" 
  self.record_timestamps = false
end
class PhoenixMembership < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "memberships" 
  self.record_timestamps = false
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
    TEST_EMAIL ? "test#{member.id}@xagax.com" : phoenix_email
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
  def member(a)
    PhoenixMember.find_by_id_and_club_id(a.member_id, CLUB)
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
  def member(a)
    PhoenixMember.find_by_id_and_club_id(a.member_id, CLUB)
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
class BillingMembershipCapture < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_captures" 
  self.record_timestamps = false
end
class BillingEnrollmentCapture < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_captures" 
  self.record_timestamps = false
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
  o.member_id = @member.id
  o.save!
end

def get_campaign_and_tom_id(cid)
  @campaign = BillingCampaign.find_by_id(cid)
  @tom_id = nil
  if not @campaign.nil? and @campaign.phoenix_tom_id.to_i > 0
    @tom_id = @campaign.phoenix_tom_id.to_i + 18
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

def get_terms_of_membership_name(tom_id)
  PhoenixTermsOfMembership.find_by_id(tom_id).name
end


def new_prospect(object, campaign, tom_id)
  phoenix = PhoenixProspect.new 
  phoenix.first_name = object.first_name
  phoenix.last_name = object.last_name
  phoenix.address = object.address
  phoenix.city = object.city
  phoenix.state = object.state
  phoenix.zip = object.zip
  phoenix.country = object.country
  phoenix.email = object.email_to_import
  phoenix.phone_country_code = object.phone_country_code
  phoenix.phone_area_code = object.phone_area_code
  phoenix.phone_local_number = object.phone_local_number
  phoenix.created_at = object.created_at
  phoenix.updated_at = object.created_at # It has a reason. updated_at was modified by us ^_^
  phoenix.birth_date = object.birth_date
  phoenix.joint = campaign.is_joint
  phoenix.marketing_code = campaign.marketing_code
  phoenix.terms_of_membership_id = tom_id
  phoenix.referral_host = campaign.referral_host
  phoenix.landing_url = campaign.landing_url
  phoenix.mega_channel = campaign.phoenix_mega_channel
  phoenix.product_sku = campaign.product_sku
  phoenix.fulfillment_code = campaign.fulfillment_code
  phoenix.product_description = campaign.product_description
  phoenix.campaign_medium = campaign.campaign_medium
  phoenix.campaign_description = campaign.campaign_description
  phoenix.campaign_medium_version = campaign.campaign_medium_version
  phoenix.preferences = JSON.generate({ :old_id => object.id })
  phoenix.referral_parameters = JSON.generate({})
  phoenix.gender = object.gender
  phoenix.club_id = CLUB
  phoenix.save!
  phoenix
end
