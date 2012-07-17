#!/bin/ruby

# litle
# insert into payment_gateway_configurations (report_group , merchant_key, login, password,  mode ,descriptor_name , descriptor_phone , order_mark , gateway , club_id ,  created_at , updated_at, deleted_at ) values (  'onmc' ,'021410', 'NMP', 'T6Uzs2Qf', 'production', 'NMP*Nascar Members Club Charlotte NC', '18776962722', NULL, 'litle', 1, NOW(), NOW(), NOW() );
# mes
# insert into payment_gateway_configurations (report_group , merchant_key, login, password,  mode ,descriptor_name , descriptor_phone , order_mark , gateway , club_id ,  created_at , updated_at ) values (  'ONMC' ,'SAC Inc', '94100011002800000002', 'OMqwczjeoonNkqqBejfHtKLoBfxLqSdi', 'production', 'NMP*ONMC', '342525', 'onmc', 'mes', 1, NOW(), NOW());

# "Email Name ","MLID","Trigger ID","Corresponding Event Name","Recurring","Before or After","Day","Notes"

@annual_sloop = [
  [ "Welcome E-mail SLOOP",47386,6411,"Join","no","After",0, nil ],
  [ "Activation E-mail", 47386, 9400, nil ,"no", nil ,nil ],
  [ "Trial Comm-Day 7",47386,6417,"Join","no","After",7,],
  [ "Pre Bill",47623,6426,"NBD","yes","Before",7,],
  [ "Pillar 1 - Deals & Discounts",47386,6418,"Join","no","After",35,],
  [ "Pillar 2 - Content",47386,6419,"Join","no","After",40,],
  [ "Pillar 3 - VIP",47386,6420,"Join","no","After",45,],
  [ "Pillar 4 - Local",47386,6421,"Join","no","After",50,],
  [ "Cancellation",47386,6424,"Cancel","no","After",0,],
  [ "Cancel with Refund ",47386,19144,"Refund","no","After",0,],
  [ "Renewal Pre Bill",47623,6427,"NBD; Member > 350 days","yes","Before",7,],
  [ "ONMC Newsletter - Annual Activated",116804,"-","Every Thursday","yes",],
  [ "ONMC Newsletter - Annual Not Activated",116804,"-","Every Thursday","yes",],
  [ "Forgot Password - Customer Service Initiated",9398,183590,"?","no","After",0,nil],
  [ "Forgot Password - Member Initiated at ONMC.COM",9399,183590,"?","no","After",0,nil],
  [ "Active Member Birthday E-mail",6434,47528,"?","yes","After","Platform: Birthday",nil],
  [ "Local Chapter Newsletter",116804,"-","Monthly - 2nd Tuesday","yes",]
]

# rename 'Renewal Pre Bill" =>  to "Pre Bill" only on this csv
@annual_join_now = [
  [ "Welcome E-mail SLOOP",47386,6411,"Join","no","After",0,],
  [ "Welcome E-mail Canadians",47386,6412,"Join","no","After",0],
  [ "Activation E-mail",47386,9400,nil,"no",nil,nil],
  [ "Pillar 1 - Deals & Discounts",47386,6418,"Join","no","After",2,],
  [ "Pillar 2 - Content",47386,6419,"Join","no","After",4,],
  [ "Pillar 3 - VIP",47386,6420,"Join","no","After",6,],
  [ "Pillar 4 - Local",47386,6421,"Join","no","After",8,],
  [ "Cancellation",47386,6424,"Cancel","no","After",0,],
  [ "Cancel with Refund ",47386,19144,"Refund","no","After",0,],
  # [ "Renewal Pre Bill",47623,6427,"NBD; Member > 350 days","yes","Before",7,],
  [ "Pre Bill",47623,6427,"NBD; Member > 350 days","yes","Before",7,],
  [ "ONMC Newsletter - Annual Activated",116804,"-","Every Thursday","yes",],
  [ "ONMC Newsletter - Annual Not Activated",116804,"-","Every Thursday","yes",],
  [ "Forgot Password - Customer Service Initiated",9398,183590,"?","no","After",0,],
  [ "Forgot Password - Member Initiated at ONMC.COM",9399,183590,"?","no","After",0,],
  [ "Active Member Birthday E-mail",6434,47528,"?","yes","After","Platform: Birthday",],
  [ "Local Chapter Newsletter",116804,"-","Monthly - 2nd Tuesday","yes",nil,nil,nil]
]

@annual_ptx = [
  [ "Welcome E-mail PTX",47386,6414,"Join","no","After",0], 
  [ "Welcome E-mail Canadians",47386,6412,"Join","no","After",0], 
  [ "Activation E-mail",47386,9400,nil,"no",nil,nil ], 
  [ "Trial Comm-Day 7",47386,6417,"Join","no","After",7], 
  [ "Pre Bill",47623,6426,"NBD","yes","Before",7], 
  [ "Pillar 1 - Deals & Discounts",47386,6418,"Join","no","After",35], 
  [ "Pillar 2 - Content",47386,6419,"Join","no","After",40], 
  [ "Pillar 3 - VIP",47386,6420,"Join","no","After",45], 
  [ "Pillar 4 - Local",47386,6421,"Join","no","After",50], 
  [ "Cancellation",47386,6424,"Cancel","no","After",0], 
  [ "Cancel with Refund ",47386,19144,"Refund","no","After",0], 
  [ "Renewal Pre Bill",47623,6427,"NBD; Member > 350 days","yes","Before",7], 
  [ "ONMC Newsletter - Annual Activated",116804,"-","Every Thursday","yes",nil,nil ], 
  [ "ONMC Newsletter - Annual Not Activated",116804,"-","Every Thursday","yes",nil,nil ], 
  [ "Forgot Password - Customer Service Initiated",9398,183590,"?","no","After",0], 
  [ "Forgot Password - Member Initiated at ONMC.COM",9399,183590,"?","no","After",0], 
  [ "Active Member Birthday E-mail",6434,47528,"?","yes","After","Platform: Birthday"], 
  [ "Local Chapter Newsletter",116804,"-","Monthly - 2nd Tuesday","yes",nil,nil ]
]

@monthly_sloops = [
  [ "Welcome E-mail SLOOP",47386,6411,"Join","no","After",0],
  [ "Activation E-mail",47386,9400,nil ,"no",nil,nil ],
  [ "Pillar 1 - Deals & Discounts",47386,6418,"Join","no","After",2],
  [ "Pillar 2 - Content",47386,6419,"Join","no","After",4],
  [ "Pillar 3 - VIP",47386,6420,"Join","no","After",6],
  [ "Pillar 4 - Local",47386,6421,"Join","no","After",8],
  [ "Pre Bill",47623,6426,"NBD","yes","Before",7],
  [ "Cancellation",47386,6424,"Cancel","no","After",0],
  [ "Cancel with Refund ",47386,19144,"Refund","no","After",0],
  [ "ONMC Newsletter - Monthly Activated",116804,"-","Every Thursday","yes",nil,nil ],
  [ "ONMC Newsletter - Monthly Not Activated",116804,"-","Every Thursday","yes",nil,nil ],
  [ "Forgot Password - Customer Service Initiated",9398,183590,"?","no","After",0,nil],
  [ "Forgot Password - Member Initiated at ONMC.COM",9399,183590,"?","no","After",0,nil],
  [ "Active Member Birthday E-mail",6434,47528,"?","yes","After","Platform: Birthday",nil],
  [ "Local Chapter Newsletter",116804,"-","Monthly - 2nd Tuesday","yes",nil,nil ]
]

def add_email_template(name, type, tom_id, trigger_id, mlid, site_id, days_after_join_date = 0)
  et = PhoenixEmailTemplate.new 
  et.name = name
  et.client = :lyris
  et.days_after_join_date = days_after_join_date.to_i
  et.template_type = type
  et.external_attributes = { :trigger_id => trigger_id, :mlid => mlid, :site_id => site_id } 
  et.terms_of_membership_id = tom_id
  et.save
end
 

# "Email Name ","MLID","Trigger ID","Corresponding Event Name","Recurring","Before or After","Day","Notes"
def upload_email_services(communications, tom_id)
  communications.each do |comm|
    type, days = nil, nil
    if comm[0] == 'Activation E-mail'
      type = :active
    elsif comm[0] == 'Pre Bill'
      type = :prebill
    elsif comm[0] == 'Cancellation'
      type = :cancellation
    elsif comm[0] == 'Cancel with Refund'
      type = :refund
    # we will have prebill renewal on phoenix 1.1
    # elsif comm[0] == 'Renewal Pre Bill'
    #  type = :prebill_renewal
    elsif comm[0].include?('Trial Comm-Day 7')
      type = :pillar
      days = comm[6]
    elsif comm[0].include?('Pillar')
      type = :pillar
      days = comm[6]
    elsif comm[0].include?('Active Member Birthday E-mail')
      type = :birthday
    end
    add_email_template(comm[0], type, tom_id, comm[2], comm[1], SITE_ID, days) unless type.nil?
  end
end



# "CID ","TOM PROVISIONAL_DAYS","Mega Channel","TOM Membership_amount","Tom Membership_Type","Campaign Description","Campaign Medium","Campaign Medium Version ","Referral Host","Marketing Code","fulfillment_code","Product Description","Product ID ","Landing URL  ","Notes","Joint"
def get_terms_of_membership_id(campaign_id)
  grace_period = 0
  campaign = BillingCampaign.find_by_id(campaign_id)
  return nil if campaign.nil? 
  return campaign.phoenix_tom_id unless campaign.phoenix_tom_id.nil?

  if campaign.terms_of_membership_id.to_i == 0 
    return nil
  elsif campaign.terms_of_membership_id.to_i == 365 
    payment_type = '1.year'
  else
    payment_type = '1.month' 
  end

  return nil if campaign.phoenix_mega_channel != 'SLOOP' and campaign.phoenix_mega_channel != 'PTX' and campaign.phoenix_mega_channel != 'OTHER'

  name = "#{payment_type} - #{campaign.phoenix_mega_channel} - #{campaign.phoenix_amount}"
  # find uses name because TOMs differ between mega_channel (emails are diff).
  m = PhoenixTermsOfMembership.find_by_club_id_and_name(CLUB, name)

  if m.nil?
    m = PhoenixTermsOfMembership.new 
    m.installment_amount = campaign.phoenix_amount
    m.installment_type = payment_type
    m.needs_enrollment_approval = false
    m.name = name
    m.description = m.name
    m.grace_period = grace_period
    m.club_id = CLUB
    m.provisional_days = campaign.phoenix_trial_days
    m.mode = "production"
    m.club_cash_amount = 150
    m.save!

    if campaign.terms_of_membership_id.to_i == 365
      if campaign.phoenix_mega_channel == 'PTX'
        upload_email_services(@annual_ptx, m.id)
      end
      if campaign.phoenix_mega_channel.include?('SLOOP')
        upload_email_services(@annual_sloop, m.id)
      end
      if campaign.phoenix_mega_channel.include?('OTHER')
        upload_email_services(@annual_join_now, m.id)
      end
    else
      if campaign.phoenix_mega_channel.include?('SLOOP')
        upload_email_services(@monthly_sloops, m.id)
      end
    end
  end
  campaign.phoenix_tom_id = m.id
  campaign.save
  m.id
end

def get_terms_of_membership_name(tom_id)
  PhoenixTermsOfMembership.find_by_id(tom_id).name
end

