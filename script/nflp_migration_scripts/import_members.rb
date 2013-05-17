#!/bin/ruby

require './import_models'

@log = Logger.new('log/import_members.log', 10, 10024000)
ActiveRecord::Base.logger = @log

KIT_CARD_FULFILLMENT = "KIT-CARD"

def add_fulfillment(member)
  if @campaign.product_sku.to_s.size > 3
    phoenix_f = PhoenixFulfillment.find_or_create_by_member_id @member.id
    phoenix_f.tracking_code = KIT_CARD_FULFILLMENT+@member.id.to_s
    phoenix_f.product_package = KIT_CARD_FULFILLMENT
    phoenix_f.product_sku = KIT_CARD_FULFILLMENT
    renewdate = member.join_date_time + (Date.today.year - member.join_date_time.year).years
    phoenix_f.renewable_at = (renewdate > Date.today ? renewdate : renewdate.next_year)
    phoenix_f.assigned_at = (phoenix_f.renewable_at - 1.year)
    phoenix_f.recurrent = true
    phoenix_f.status = "sent"
    phoenix_f.save! if phoenix_f.changed? 
  end
end

def remove_fulfillment
  phoenix_f = PhoenixFulfillment.find_by_member_id @member.id
  phoenix_f.destroy unless phoenix_f.nil?
end

def set_member_data(phoenix, member)
  phoenix.first_name = member.first_name
  phoenix.last_name = member.last_name
  phoenix.email = member.email_to_import
  phoenix.address = member.address
  phoenix.city = member.city
  phoenix.state = member.state
  phoenix.zip = member.phoenix_zip
  phoenix.country = member.country
  phoenix.birth_date = member.birth_date
  phoenix.phone_country_code = member.phone_country_code
  phoenix.phone_area_code = member.phone_area_code
  phoenix.phone_local_number = member.phone_local_number
  phoenix.reactivation_times = member.phoenix_reactivations
  phoenix.preferences = JSON.generate({  })
  # phoenix.gender
  phoenix.blacklisted = member.blacklisted
  phoenix.api_id = member.drupal_account_id
  phoenix.club_cash_expire_date = nil
  phoenix.club_cash_amount = 0
  phoenix.created_at = member.created_at
  phoenix.updated_at = member.updated_at
  phoenix.member_since_date = convert_from_date_to_time(member.member_since_date)
end

def add_enrollment_info(phoenix, member, tom_id, campaign = nil)
  campaign = BillingCampaign.find_by_id(member.campaign_id) if campaign.nil?
  @e_info.enrollment_amount = member.enrollment_amount_to_import
  @e_info.product_sku = campaign.product_sku
  @e_info.product_description = campaign.product_description
  @e_info.mega_channel = campaign.phoenix_mega_channel
  @e_info.marketing_code = campaign.marketing_code
  @e_info.fulfillment_code = campaign.fulfillment_code
  @e_info.referral_host = campaign.referral_host
  @e_info.landing_url = campaign.landing_url
  @e_info.terms_of_membership_id = tom_id
  @e_info.preferences = JSON.generate({  })
  @e_info.created_at = member.join_date_time
  @e_info.updated_at = member.join_date_time
  @e_info.campaign_medium = campaign.campaign_medium
  @e_info.campaign_description = campaign.campaign_description
  @e_info.campaign_medium_version = campaign.campaign_medium_version
  @e_info.joint = campaign.is_joint
  if @e_info.prospect_id.nil?
    prospect = ProspectProspect.where(" member_id_updated = '#{member.id}' ").first
    if prospect.nil? #https://redmine.xagax.com/issues/25731#note-7
      @e_info.prospect_id = new_prospect(member, campaign, tom_id, member.join_date_time).id
    else
      @e_info.prospect_id = new_prospect(prospect, campaign, tom_id, member.join_date_time).id
    end
  end
  @e_info.save if @e_info.changed?
end

def set_membership_data(tom_id, member)
  membership = PhoenixMembership.find_by_member_id(@member.id) || PhoenixMembership.new(:member_id => @member.id)
  membership.terms_of_membership_id = tom_id
  membership.created_by_id = DEFAULT_CREATED_BY
  membership.join_date = member.join_date_time
  membership.status = @member.status
  membership.quota = member.quota
  membership.created_at = member.join_date_time
  membership.updated_at = member.updated_at
  membership.member_id = @member.id
  membership.cancel_date = member.cancelled_at
  membership.save! if membership.changed? 

  if membership.status == 'lapsed'
    cancel_date = membership.cancel_date
    add_operation(cancel_date, 'Membership', membership.id, "Member canceled", Settings.operation_types.cancel, cancel_date, cancel_date) 
  end

  @member.current_membership_id = membership.id
  @member.save if @member.changed?
  @e_info.membership_id = membership.id
  @e_info.save if @e_info.changed?
end

def set_member_bill_dates(member, phoenix)
  next_bill_date = convert_from_date_to_time(member.cs_next_bill_date)
  phoenix.bill_date, phoenix.next_retry_bill_date = next_bill_date, next_bill_date 
  if member.phoenix_status != 'active' and member.phoenix_status != 'provisional'
    phoenix.bill_date, phoenix.next_retry_bill_date = nil, nil
  end  
end

# 2- import new members.
def add_new_members
  BillingMember.where(" imported_at IS NULL and is_prospect = false " +
      " AND member_since_date IS NOT NULL AND campaign_id IS NOT NULL AND join_date_time IS NOT NULL " +
      " AND blacklisted = true AND phoenix_status = 'lapsed' AND phoenix_email IS NOT NULL " +
      " AND credit_card_token IS NOT NULL ").find_in_batches do |group|

    puts "cant #{group.count}"
    group.each do |member| 
      get_campaign_and_tom_id(member.campaign_id)
      if @tom_id.nil?
        puts "CDId #{member.campaign_id} does not exist or TOM is empty"
        next
      end

      tz = Time.now.utc
      # transactions between databases does not work
      @log.info "  * processing member ##{member.id}"
      begin

        # validate if email already exist
        phoenix = PhoenixMember.find_by_email_and_club_id member.email_to_import, CLUB
        unless phoenix.nil?
          puts "Email #{member.email_to_import} already exists"
          next
        end

        phoenix = PhoenixMember.new 
        phoenix.club_id = CLUB
        phoenix.id = member.id
        set_member_data(phoenix, member)
        phoenix.status = member.phoenix_status
        phoenix.recycled_times = 0
        set_member_bill_dates(member, phoenix)
        phoenix.save!

        @e_info = PhoenixEnrollmentInfo.find_by_member_id(phoenix.id) || PhoenixEnrollmentInfo.new(:member_id => phoenix.id)
        @member = phoenix
        add_enrollment_info(phoenix, member, @tom_id, @campaign)
        add_operation(Time.now.utc, nil, nil, "Member imported into phoenix!", nil)  

        # create CC
        phoenix_cc = PhoenixCreditCard.new 
        fill_credit_card(phoenix_cc, member, phoenix)
        phoenix_cc.save! 

        # create Membership data
        set_membership_data(@tom_id, member)

        blacklist_ccs(member, phoenix)

        if member.phoenix_status == 'lapsed'
          remove_fulfillment
        else
          add_fulfillment(member)
        end

        member.update_attribute :imported_at, Time.now.utc
        print "."
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
        return
      end
      @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
    end
  end
end

def blacklist_ccs(member, phoenix)
  if member.blacklisted
    ccs = PhoenixCreditCard.find_all_by_member_id_and_blacklisted(phoenix.id, false)
    ccs.each {|s| s.update_attribute :blacklisted, true }
  end  
end

def fill_credit_card(phoenix_cc, member, phoenix)
  phoenix_cc.token = member.credit_card_token
  phoenix_cc.expire_month = member.cc_month_exp
  phoenix_cc.expire_year = member.cc_year_exp
  phoenix_cc.created_at = member.created_at
  phoenix_cc.cc_type = member.credit_card_type
  phoenix_cc.last_digits = member.credit_card_last_digits
  phoenix_cc.updated_at = member.updated_at
  phoenix_cc.member_id = phoenix.id
end


# update_members
add_new_members

