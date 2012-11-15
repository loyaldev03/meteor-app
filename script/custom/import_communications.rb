#!/bin/ruby

# litle
# insert into payment_gateway_configurations (report_group , merchant_key, login, password,  mode ,descriptor_name , descriptor_phone , order_mark , gateway , club_id ,  created_at , updated_at, deleted_at ) values (  'onmc' ,'021410', 'NMP', 'T6Uzs2Qf', 'production', 'NMP*Nascar Members Club Charlotte NC', '18776962722', NULL, 'litle', 1, NOW(), NOW(), NOW() );
# mes
# insert into payment_gateway_configurations (report_group , merchant_key, login, password,  mode ,descriptor_name , descriptor_phone , order_mark , gateway , club_id ,  created_at , updated_at ) values (  'ONMC' ,'SAC Inc', '94100011002800000002', 'OMqwczjeoonNkqqBejfHtKLoBfxLqSdi', 'production', 'NMP*ONMC', '342525', 'onmc', 'mes', 1, NOW(), NOW());



# "CID ","TOM PROVISIONAL_DAYS","Mega Channel","TOM Membership_amount","Tom Membership_Type","Campaign Description","Campaign Medium","Campaign Medium Version ","Referral Host","Marketing Code","fulfillment_code","Product Description","Product ID ","Landing URL  ","Notes","Joint"
def get_terms_of_membership_id(campaign_id)
  grace_period = 0
  if campaign_id.nil?
    # refs #18932 , members without CID are complementary. This means we have to set them a lifetime TOM.
    
  end
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

  return nil unless ['LG2C', 'SLOOP', 'PTX', 'OTHER'].include?(campaign.phoenix_mega_channel)

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
    # refs to 19806
    if campaign.terms_of_membership_id.to_i == 365
      m.club_cash_amount = 150
    else
      m.club_cash_amount = 12
    end
    m.save!
  end
  campaign.phoenix_tom_id = m.id
  campaign.save
  m.id
end

def get_terms_of_membership_name(tom_id)
  PhoenixTermsOfMembership.find_by_id(tom_id).name
end

