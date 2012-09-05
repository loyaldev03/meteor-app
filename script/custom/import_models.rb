# 1- Get access to phoenix, billing_component, customer_services and prospect databases
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

CREDIT_CARD_NULL = "0000000000"
USE_MEMBER_LIST = true

@cids = %w(
190
225
10
14
15
16
19
20
21
23
26
28
29
31
32
33
34
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
298
299
321
322
323
1123
1124
1141
1142
1143
1144
1145
1146
1147
1148
1149
1150
1151
1152
1153
1154
1155
1156
1157
1158
1159
1160
1169
1170
1140
1183
1184
1185
1186
1187
1188
1311
1312
1313
1394
1395
1396
1397
1400
1401
1402
1403
1466
1467
1468
1469
1548
1549
1550
1551
1552
1553
1554
1555
1556
1557
1558
1559
1560
1561
1562
1563
1564
1565
1566
1567
1568
1569
1570
1571
1572
1573
1574
1575
1576
1577
1578
1579
1580
1581
1582
1583
1584
1585
1586
1587
1588
1589
1590
1591
1592
1593
1594
1595
1596
1597
1598
1599
1600
1601
1602
1603
1604
1605
1606
1607
1677
1678
999
1221
1222
1223
1224
1225
1226
1227
1228
1229
1230
1231
1232
1233
1235
1236
1237
1238
1239
1234
1246
1247
1248
1249
1250
1251
1252
1253
1254
1256
1257
1258
1285
1286
1287
1288
1289
1290
1291
1292
1293

)



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
  serialize :preferences, JSON
  serialize :referral_parameters, JSON

  def email_to_import
    TEST ? "test#{member.id}@xagax.com" : email
  end  
end



class PhoenixMember < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "members" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

  def self.cohort_formula(join_date, enrollment_info, time_zone, installment_type)
    [ join_date.in_time_zone(time_zone).year.to_s, 
      "%02d" % join_date.in_time_zone(time_zone).month.to_s, 
      enrollment_info.mega_channel.to_s.strip, 
      enrollment_info.campaign_medium.to_s.strip,
      installment_type ].join('-').downcase
  end 

  def phone_number=(phone)
    p = phone.gsub(/[\s~\(\/\-=\)\_\.]/, '')
    if p.size == 10 || p.size == 9
      phone_country_code = '1'
      phone_area_code = p[0..2]
      phone_local_number = p[3..-1]
    elsif p.size == 11
      phone_country_code = p[0..0]
      phone_area_code = p[1..3]
      phone_local_number = p[4..-1]
    elsif p.size == 12
      phone_country_code = p[0..1]
      phone_area_code = p[2..4]
      phone_local_number = p[5..-1]
    elsif p.size == 13
      phone_country_code = p[0..1]
      phone_area_code = p[2..5]
      phone_local_number = p[6..-1]
    elsif p.size < 5 || p.include?('@')
    else
      raise "Dont know how to parse -#{p}-"
    end
  end
end

class PhoenixProspect < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "prospects" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

  serialize :preferences, JSON
  serialize :referral_parameters, JSON

# 3304940833ext412

  def phone_number=(phone)
    p = phone.gsub(/[\s~\(\/\-=\)"\_\.+]/, '')
    if p.size == 7 
      phone_country_code = '1'
      phone_local_number = p
    elsif p.size == 10 || p.size == 9
      phone_country_code = '1'
      phone_area_code = p[0..2]
      phone_local_number = p[3..-1]
    elsif p.size == 11
      phone_country_code = p[0..0]
      phone_area_code = p[1..3]
      phone_local_number = p[4..-1]
    elsif p.size == 12
      phone_country_code = p[0..1]
      phone_area_code = p[2..4]
      phone_local_number = p[5..-1]
    elsif p.size == 13
      phone_country_code = p[0..1]
      phone_area_code = p[2..5]
      phone_local_number = p[6..-1]
    elsif p.size < 5 || p.include?('@')
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
  def capture
    if authorization.litleTxnId.to_s.size > 2
     BillingEnrollmentCapture.find_by_member_id_and_litleTxnId(authorization.member_id, authorization.litleTxnId)
    else
     nil
    end
  end
  def capture_response
    capture.nil? ? nil : BillingEnrollmentCaptureResponse.find_by_capture_id(capture.id)
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
  def capture
    if authorization.litleTxnId.to_s.size > 2
      BillingMembershipCapture.find_by_member_id_and_litleTxnId(authorization.member_id, authorization.litleTxnId)
    else
      nil
    end
  end
  def invoice_number(a)
    "#{self.created_at.to_date}-#{a.member_id}"
  end
  def capture_response
    capture.nil? ? nil : BillingMembershipCaptureResponse.find_by_capture_id(capture.id)
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

def load_cancellation(cancel_date)
  add_operation(cancel_date, @member, "Member canceled", Settings.operation_types.cancel, cancel_date, cancel_date) 
end

def set_last_billing_date_on_credit_card(member, transaction_date)
  cc = PhoenixCreditCard.find_by_active_and_member_id true, member.id
  if cc and (cc.last_successful_bill_date.nil? or cc.last_successful_bill_date < transaction_date)
    cc.update_attribute :last_successful_bill_date, transaction_date
  end
end

require 'import_communications'
