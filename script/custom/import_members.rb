#!/bin/ruby

require './import_models'

@log = Logger.new('log/import_members.log', 10, 1024000)
ActiveRecord::Base.logger = @log

KIT_CARD_FULFILLMENT = "KIT-CARD"

def add_fulfillment(member)
  unless @campaign.product_sku.empty?
    phoenix_f = PhoenixFulfillment.find_or_create_by_member_id @member.uuid
    phoenix_f.tracking_code = KIT_CARD_FULFILLMENT+@member.visible_id.to_s
    phoenix_f.product_package = KIT_CARD_FULFILLMENT
    phoenix_f.product_sku = KIT_CARD_FULFILLMENT
    phoenix_f.assigned_at = Time.now.utc
    renewdate = member.phoenix_join_date + (Date.today.year - member.phoenix_join_date.year).years
    phoenix_f.renewable_at = (renewdate > Date.today ? renewdate : renewdate.next_year)
    phoenix_f.recurrent = true
    phoenix_f.status = "not_processed"
    phoenix_f.save!  
  end
end

def remove_fulfillment
  phoenix_f = PhoenixFulfillment.find_by_member_id @member.uuid
  phoenix_f.destroy unless phoenix_f.nil?
end

def set_member_data(phoenix, member, merge_member = false)
  phoenix.first_name = member.first_name
  phoenix.last_name = member.last_name
  phoenix.email = member.email_to_import
  phoenix.address = member.address
  phoenix.city = member.city
  phoenix.state = member.state
  phoenix.zip = member.zip
  phoenix.country = member.country
  phoenix.birth_date = member.birth_date
  phoenix.phone_country_code = member.phone_country_code
  phoenix.phone_area_code = member.phone_area_code
  phoenix.phone_local_number = member.phone_local_number
  phoenix.reactivation_times = member.phoenix_reactivations
  phoenix.preferences = { :driver_1 => member.fav_driver1, :driver_2 => member.fav_driver2, :track => member.fav_track, :car => member.fav_car }
  # phoenix.gender
  phoenix.blacklisted = member.blacklisted
  phoenix.api_id = member.api_id
  phoenix.club_cash_expire_date = nil
  phoenix.club_cash_amount = 0
  if member.is_chapter_member
    phoenix.member_group_type_id = MEMBER_GROUP_TYPE
  else
    phoenix.member_group_type_id = nil
  end
  unless merge_member
    phoenix.created_at = member.created_at
    phoenix.updated_at = member.updated_at
    phoenix.member_since_date = convert_from_date_to_time(member.member_since_date)
  end
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
  @e_info.preferences = { :driver_1 => member.fav_driver1, :driver_2 => member.fav_driver2, :track => member.fav_track, :car => member.fav_car }
  @e_info.created_at = member.created_at
  @e_info.updated_at = member.updated_at
  @e_info.campaign_medium = campaign.campaign_medium
  @e_info.campaign_description = campaign.campaign_description
  @e_info.campaign_medium_version = campaign.campaign_medium_version
  @e_info.joint = campaign.is_joint
  if @e_info.prospect_id.nil?
    prospect = ProspectProspect.where(" member_id = '#{member.id}' ").first
    if prospect.nil? #https://redmine.xagax.com/issues/25731#note-7
      @e_info.prospect_id = new_prospect(member, campaign, tom_id).id
    else
      @e_info.prospect_id = new_prospect(prospect, campaign, tom_id).id
    end
  end
  @e_info.save
end

def fill_aus_attributes(cc, member)
  cc.aus_status = member.aus_status
  cc.aus_answered_at = member.aus_answered_at
  cc.aus_sent_at = member.aus_sent_at
end

def set_membership_data(tom_id, member)
  membership = PhoenixMembership.find_or_create_by_member_id @member.id
  membership.terms_of_membership_id = tom_id
  membership.created_by_id = DEFAULT_CREATED_BY
  membership.join_date = convert_from_date_to_time(member.phoenix_join_date)
  membership.status = @member.status
  membership.quota = member.quota
  membership.created_at = member.created_at
  membership.updated_at = member.updated_at
  membership.member_id = @member.id
  membership.cancel_date = member.cancelled_at
  membership.save!
  @member.current_membership_id = membership.id
  @member.save
  @e_info.membership_id = membership.id
  @e_info.save
end

def set_member_bill_dates(member, phoenix)
  next_bill_date = convert_from_date_to_time(member.cs_next_bill_date)
  original_bill_date = member.original_next_bill_date.nil? ? next_bill_date : convert_from_date_to_time(member.original_next_bill_date)

  if member.phoenix_status == 'active'
    phoenix.bill_date, phoenix.next_retry_bill_date = original_bill_date, next_bill_date 
  elsif member.phoenix_status == 'provisional'
    phoenix.bill_date = original_bill_date 
    phoenix.next_retry_bill_date = next_bill_date 
    if @campaign.terms_of_membership_id.to_i == 365 
      phoenix.bill_date = member.original_next_bill_date.nil? ? phoenix.join_date : convert_from_date_to_time(member.original_next_bill_date) 
    end
  else
    phoenix.bill_date, phoenix.next_retry_bill_date = nil, nil
  end  
end


# 1- update existing members
def update_members
  BillingMember.where("imported_at IS NOT NULL AND (updated_at > imported_at or phoenix_updated_at > imported_at) " + 
    " and is_prospect = false ").find_in_batches do |group|
    group.each do |member| 
    puts "cant #{group.count}"
      tz = Time.now.utc
      get_campaign_and_tom_id(member.campaign_id)
      if @tom_id.nil?
        puts "CDId #{member.campaign_id} does not exist or TOM is empty"
        next
      end

      @log.info "  * processing member ##{member.id}"
      begin
        phoenix = PhoenixMember.find_by_club_id_and_visible_id(CLUB, member.id)
        @e_info = PhoenixEnrollmentInfo.find_or_create_by_member_id(phoenix.id)
        if phoenix.nil?
          puts "  * member ##{member.id} not found on phoenix ?? "
          next
        end
        
        @member = phoenix
        set_member_data(phoenix, member)
        add_enrollment_info(phoenix, member, @tom_id)
        set_member_bill_dates(member, phoenix)
        phoenix.save!

        # create Membership data
        set_membership_data(@tom_id, member)

        phoenix_cc = PhoenixCreditCard.find_by_member_id_and_active(phoenix.uuid, true)

        new_phoenix_cc = PhoenixCreditCard.new 
        fill_credit_card(new_phoenix_cc, member, phoenix)
        if phoenix_cc.nil?
          @log.info "  * member ##{member.id} does not have Credit Card active"
          new_phoenix_cc.save!
        elsif phoenix_cc.token != member.credit_card_token
          phoenix_cc.active = false
          new_phoenix_cc.save!
          phoenix_cc.save!
        else
          phoenix_cc.expire_month = member.cc_month_exp 
          phoenix_cc.expire_year = member.cc_year_exp
          fill_aus_attributes(phoenix_cc, member)
          phoenix_cc.save!
        end
        
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
      end
    end
    @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
  end
end


# 2- import new members.
def add_new_members
  BillingMember.where(" imported_at IS NULL and is_prospect = false " + 
     #" and id <= 11325442002 " + 
      " and credit_card_token IS NOT NULL and phoenix_status IN ('active', 'provisional') ").find_in_batches do |group|
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
        phoenix.visible_id = member.id
        set_member_data(phoenix, member)
        phoenix.status = member.phoenix_status
        phoenix.recycled_times = 0
        set_member_bill_dates(member, phoenix)
        phoenix.save!

        @e_info = PhoenixEnrollmentInfo.find_or_create_by_member_id(phoenix.id)
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
    ccs = PhoenixCreditCard.find_by_member_id_and_blacklisted(phoenix.uuid, false)
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
  fill_aus_attributes(phoenix_cc, member)
  phoenix_cc.member_id = phoenix.uuid
end


# if we use load_duplicated_emails , update_members will override changes.
# update_members

add_new_members

