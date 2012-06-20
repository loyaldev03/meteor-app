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

CLUB = 2
DEFAULT_CREATED_BY = 2
PAYMENT_GW_CONFIGURATION = 2
TEST = true

@log = Logger.new('import_members.log', 10, 1024000)
ActiveRecord::Base.logger = @log

# add phoenix database connection
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

class ProspectProspect < ActiveRecord::Base
  establish_connection "prospect" 
  self.table_name = "prospects" 
  serialize :preferences, JSON
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

class Settings < Settingslogic
  source "#{File.expand_path(File.dirname(__FILE__))}/../../config/application.yml"
  namespace Rails.env
end




class BillingMember < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "members" 
end
class BillingCampaign < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "campaigns" 
end
class BillingEnrollmentAuthorizationResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_auth_responses" 
  def authorization
    BillingEnrollmentAuthorization.find_by_id(self.authorization_id)
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
end
class BillingEnrollmentCapture < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_captures" 
end
class BillingEnrollmentCaptureResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_capt_responses" 
end
class BillingMembershipAuthorizationResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_auth_responses" 
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
end
class BillingMembershipCapture < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_captures" 
end
class BillingMembershipCaptureResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_capt_responses" 
end
class BillingChargeback < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "chargebacks" 
end



class CustomerServicesOperations < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "operations"
end
class CustomerServicesNotes < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "notes"
end
class CustomerServicesNoteType < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "note_types" 
end
class CustomerServicesCommunication < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "communications" 
end



########################################################################################################
###########################   FUNCTIONS             ####################################################
########################################################################################################

#TODO => 
def get_enrollment_amount(campaign_id)
  BillingCampaign.find_by_id()
end
# TODO: use campaign id to find this value!
def get_terms_of_membership_id(campaign_id)
  1
end
# TODO: => 
def get_terms_of_membership_name(tom_id)
  "test"
end
# TODO: => 
def get_agent(author = 999)
  if author == 999
    DEFAULT_CREATED_BY
  else
    DEFAULT_CREATED_BY
  end
end

def add_operation(operation_date, object, description, operation_type, created_at = Time.zone.now, updated_at = Time.zone.now, author = 999)
  # TODO: levantamos los Agents?
  #current_agent = Agent.find_by_email('batch@xagax.com') if author == 999
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
  tz = Time.now
  begin
    @log.info "  * processing member ##{@member.uuid}"
    add_operation(@member.cancel_date, @member, "Member canceled", Settings.operation_types.cancel, @member.cancel_date, @member.cancel_date) 
  rescue Exception => e
    @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    exit
  end
  @log.info "    ... took #{Time.now - tz} for member ##{@member.uuid}"
end
