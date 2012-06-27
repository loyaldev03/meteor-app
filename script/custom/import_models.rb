# 1- Get access to phoenix, billing_component, customer_services and prospect databases
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

require 'rails'
require 'active_record'
require 'uuidtools'
require 'attr_encrypted'
require 'settingslogic'

CLUB = 16
DEFAULT_CREATED_BY = 14
PAYMENT_GW_CONFIGURATION = 4
TERMS_OF_MEMBERSHIP = 11 # TODO: this value will be loaded from campaigns. its temporary here
TEST = true # if true email will be replaced with a fake one
SITE_ID = 2010001547 # lyris site id
USE_PROD_DB = true

@log = Logger.new('import_members.log', 10, 1024000)
ActiveRecord::Base.logger = @log

if USE_PROD_DB
  puts "by default do not continue. Uncomment this line if you want to run script. \n\t check configuration above." 
  exit
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
    :database => "sac_platform_development",
    :host => "127.0.0.1",
    :username => "root",
    :password => "root911", 
    :port => 30004 # tunnel 
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
  serialize :preferences, JSON
  serialize :referral_parameters, JSON
end



class PhoenixMember < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "members" 
  self.primary_key = 'uuid'
  serialize :enrollment_info, JSON
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'
end
class PhoenixProspect < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "prospects" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'
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
class PhoenixTransaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "transactions" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

  def set_payment_gateway_configuration
    pgc = PhoenixPGC.find(PAYMENT_GW_CONFIGURATION)
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



class Settings < Settingslogic
  source "#{File.expand_path(File.dirname(__FILE__))}/../../config/application.yml"
  namespace Rails.env
end




class BillingMember < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "members"
  self.record_timestamps = false
end
class BillingCampaign < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "campaigns" 
  self.record_timestamps = false
end
class BillingEnrollmentAuthorizationResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_auth_responses" 
  self.record_timestamps = false
  def authorization
    BillingEnrollmentAuthorization.find_by_id(self.authorization_id)
  end
  def invoice_number
    "#{self.created_at.to_date}-#{self.authorization.member_id}"
  end
  def member
    PhoenixMember.find_by_visible_id_and_club_id(authorization.member_id, CLUB)
  end
  def capture 
    BillingEnrollmentCapture.find_by_member_id_and_litleTxnId(authorization.member_id, authorization.litleTxnId)
  end
  def capture_response
    BillingEnrollmentCaptureResponse.find_by_capture_id(capture.id)
  end
  def amount
    if capture.nil?
      BillingCampaign.find(authorization.campaign_id).capture_amount
    else
      capture.amount / 100.0
    end
  end
end
class BillingEnrollmentAuthorization < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_authorizations" 
  self.record_timestamps = false
end
class BillingEnrollmentCapture < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_captures" 
  self.record_timestamps = false
end
class BillingEnrollmentCaptureResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_capt_responses" 
  self.record_timestamps = false
end
class BillingMembershipAuthorizationResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_auth_responses" 
  self.record_timestamps = false
  def authorization
    BillingMembershipAuthorization.find_by_id(self.authorization_id)
  end
  def member
    PhoenixMember.find_by_visible_id_and_club_id(authorization.member_id, CLUB)
  end
  def billing_member
    BillingMember.find_by_id(authorization.member_id)
  end
  def capture 
    BillingMembershipCapture.find_by_member_id_and_litleTxnId(authorization.member_id, authorization.litleTxnId)
  end
  def capture_response
    BillingMembershipCaptureResponse.find_by_capture_id(capture.id)
  end
  def amount
    if capture.nil?
      campaign = BillingCampaign.find_by_id(authorization.campaign_id)
      if campaign.nil? 
        campaign = if billing_member.nil?
          BillingCampaign.find_by_id(999) 
        else
          BillingCampaign.find_by_id(billing_member.campaign_id)
        end
      end
      campaign.membership_amount
    else
      capture.amount / 100.0
    end
  end
end
class BillingMembershipAuthorization < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_authorizations" 
  self.record_timestamps = false
end
class BillingMembershipCapture < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_captures" 
  self.record_timestamps = false
end
class BillingMembershipCaptureResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_capt_responses" 
  self.record_timestamps = false
end
class BillingChargeback < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "chargebacks" 
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

# TODO: use campaign id to find this value!
def get_terms_of_membership_id(campaign_id)
  TERMS_OF_MEMBERSHIP # BillingCampaign.find_by_id(campaign_id).terms_of_membership_id
end
# TODO: => 
def get_terms_of_membership_name(tom_id)
  "test"
end

def get_agent(author = 999)
  if author == 999
    DEFAULT_CREATED_BY
  else
    u = CustomerServicesUser.find_by_id(author)
    if u.nil?
      DEFAULT_CREATED_BY
    else
      a = PhoenixAgent.find_by_username(u.login)
      if a.nil?
        a = PhoenixAgent.new :username => u.login, :first_name => u.firstname, :last_name => u.lastname, 
            :email => u.mail
        a.save!
      end
      a.id
    end
  end
end

def add_operation(operation_date, object, description, operation_type, created_at = Time.now.utc, updated_at = Time.now.utc, author = 999)
  o = PhoenixOperation.new :operation_date => operation_date, :description => description, 
      :operation_type => (operation_type || Settings.operation_types.others)
  o.created_by_id = get_agent
  o.created_at = created_at
  if object.nil?
    o.resource_type = nil
    # TODO => 
    # o.resource_id = 0
  end
  o.updated_at = updated_at
  o.member_id = @member.uuid
  o.save!
end

def load_cancellation
  tz = Time.now.utc
  begin
    @log.info "  * processing member ##{@member.uuid}"
    add_operation(@member.cancel_date, @member, "Member canceled", Settings.operation_types.cancel, @member.cancel_date, @member.cancel_date) 
  rescue Exception => e
    @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    exit
  end
  @log.info "    ... took #{Time.now.utc - tz} for member ##{@member.uuid}"
end
