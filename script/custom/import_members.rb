#!/bin/ruby

require_relative 'import_models'

@log = Logger.new('import_members.log', 10, 1024000)
ActiveRecord::Base.logger = @log


def update_club_cash(amount)
  cct = PhoenixClubCashTransaction.new 
  cct.amount = amount
  cct.description = "Imported club cash"
  cct.member_id = @member.uuid
  cct.save!
  add_operation(Time.now.utc, cct, "Imported club cash transaction!. Amount: $#{cct.amount}", nil)  
end
def add_fulfillment(fulfillment_kit, fulfillment_since_date, fulfillment_expire_date)
  if not fulfillment_kit.nil? and not fulfillment_expire_date.nil? and not fulfillment_since_date.nil?
    phoenix_f = PhoenixFulfillment.new :product => fulfillment_kit
    phoenix_f.member_id = @member.uuid
    phoenix_f.assigned_at = fulfillment_since_date
    phoenix_f.delivered_at = fulfillment_since_date
    phoenix_f.renewable_at = fulfillment_expire_date
    phoenix_f.save!  
  end
end
def add_product_fulfillment(has_fulfillment_product)
  product = "Sloop"
  if has_fulfillment_product
    if PhoenixFulfillment.find_by_member_id_and_product(@member.uuid, product).nil?
      phoenix_f = PhoenixFulfillment.new 
      phoenix_f.product = product
      phoenix_f.member_id = @member.uuid
      phoenix_f.assigned_at = @member.join_date
      phoenix_f.delivered_at = @member.join_date
      phoenix_f.renewable_at = nil
      phoenix_f.save!  
    end
  end
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
  phoenix.joint = member.joint
  phoenix.birth_date = member.birth_date
  phoenix.phone_number = member.phone
  phoenix.blacklisted = member.blacklisted
  phoenix.join_date = member.phoenix_join_date
  phoenix.api_id = member.drupal_user_api_id
  phoenix.club_cash_expire_date = member.club_cash_expire_date
  if member.is_chapter_member
    phoenix.member_group_type_id = MEMBER_GROUP_TYPE
  else
    phoenix.member_group_type_id = nil
  end
  unless merge_member
    phoenix.quota = member.quota
    phoenix.reactivation_times = member.phoenix_reactivations - 1
    phoenix.created_at = member.created_at
    phoenix.updated_at = member.updated_at
    phoenix.member_since_date = member.member_since_date
  end
end
def add_enrollment_info(phoenix, member)
  e_info = PhoenixEnrollmentInfo.find_by_member_id(phoenix.id)
  if e_info.nil?
    e_info = PhoenixEnrollmentInfo.new 
    e_info.member_id = phoenix.id
  end
  campaign = BillingCampaign.find_by_id(member.campaign_id)
  e_info.enrollment_amount = member.enrollment_amount_to_import
  e_info.product_sku = campaign.product_sku
  e_info.product_description = campaign.product_description
  e_info.mega_channel = campaign.phoenix_mega_channel
  e_info.marketing_code = campaign.marketing_code
  e_info.fulfillment_code = campaign.fulfillment_code
  e_info.referral_host = campaign.referral_host
  e_info.landing_url = campaign.landing_url
  e_info.terms_of_membership_id = phoenix.terms_of_membership_id
  # e_info.preferences
  e_info.campaign_medium = campaign.campaign_medium
  e_info.campaign_description = campaign.campaign_description
  e_info.campaign_medium_version = campaign.campaign_medium_version
  e_info.joint = campaign.is_joint
  e_info.save
end
def update_fulfillment(member, phoenix)
  phoenix_f = PhoenixFulfillment.find_by_member_id_and_product(phoenix.uuid, member.fulfillment_kit)
  if phoenix_f.nil?
    add_fulfillment(member.fulfillment_kit, member.fulfillment_since_date, member.fulfillment_expire_date)
  else
    phoenix_f.product = member.fulfillment_kit
    phoenix_f.assigned_at = member.fulfillment_since_date
    phoenix_f.delivered_at = member.fulfillment_since_date
    phoenix_f.renewable_at = member.fulfillment_expire_date
    phoenix_f.save! 
  end
  add_product_fulfillment(member.has_fulfillment_product)
end
def update_member_when_duplicated_email(member, phoenix)
  if phoenix.status == member.phoenix_status
    # not imported member is newer
    if member.id > phoenix.visible_id
      set_member_data(phoenix, member, true)
      phoenix.updated_at = member.updated_at
      phoenix.visible_id = member.id
      phoenix.cancel_date = member.cancelled_at
      update_fulfillment(member, phoenix)
    else
      phoenix.created_at = member.created_at
      phoenix.member_since_date = member.member_since_date
    end
    phoenix.quota = member.quota + phoenix.quota
    phoenix.reactivation_times = member.phoenix_reactivations - 1 + phoenix.reactivation_times
    # TODO: Its hard to add every enrollment info.
    # add_enrollment_info(phoenix, member)
    phoenix.save!
    @member = phoenix
    load_cancellation(member.cancelled_at)

    phoenix_cc = PhoenixCreditCard.find_by_member_id_and_active(phoenix.uuid, true)

    new_phoenix_cc = PhoenixCreditCard.new 
    new_phoenix_cc.encrypted_number = member.encrypted_cc_number
    new_phoenix_cc.number = CREDIT_CARD_NULL if new_phoenix_cc.number.nil?
    new_phoenix_cc.expire_month = member.cc_month_exp
    new_phoenix_cc.expire_year = member.cc_year_exp
    new_phoenix_cc.member_id = phoenix.uuid
    new_phoenix_cc.active = (member.id == phoenix.visible_id)

    if phoenix_cc.nil?
      puts "  * member ##{member.id} does not have Credit Card active"
      new_phoenix_cc.save!
      add_operation(Time.zone.now, new_phoenix_cc, "Credit card #{new_phoenix_cc.last_digits} added", nil)
    elsif phoenix_cc.encrypted_number != member.encrypted_cc_number or 
          phoenix_cc.expire_month != member.cc_month_exp or 
          phoenix_cc.expire_year != member.cc_year_exp
      phoenix_cc.active = (member.id != phoenix.visible_id)
      new_phoenix_cc.save!
      phoenix_cc.save!
      add_operation(Time.zone.now, new_phoenix_cc, "Credit card #{new_phoenix_cc.last_digits} added", nil)
    end
  end
end

# 1- update existing members
def update_members
  BillingMember.where("imported_at IS NOT NULL AND (updated_at > imported_at or phoenix_updated_at > imported_at) " + 
    " and is_prospect = false and phoenix_status IS NOT NULL and phoenix_join_date IS NOT NULL ").find_in_batches do |group|
    group.each do |member| 
      tz = Time.now.utc
      PhoenixProspect.transaction do 
        @log.info "  * processing member ##{member.id}"
        begin
          phoenix = PhoenixMember.find_by_club_id_and_visible_id(CLUB, member.id)
          if phoenix.nil?
            @log.info "  * member ##{member.id} not found on phoenix ?? "
            next
          end
          
          @member = phoenix
          set_member_data(phoenix, member)
          add_enrollment_info(phoenix, member)
          #TODO: puede haber cambio de TOM  en ONMC production ?

          phoenix.bill_date = member.cs_next_bill_date
          phoenix.next_retry_bill_date = member.cs_next_bill_date
          if phoenix.status != "lapsed" and member.phoenix_status == "lapsed"
            load_cancellation(@member.cancel_date)
          end        
          phoenix.status = member.phoenix_status
          if member.phoenix_status == 'lapsed'
            phoenix.recycled_times = 0
            phoenix.cancel_date = member.cancelled_at
            phoenix.bill_date, phoenix.next_retry_bill_date = nil, nil
          end

          phoenix.save!

          if phoenix.club_cash_amount.to_f != member.club_cash_amount.to_f
            # create Club cash transaction.
            update_club_cash(member.club_cash_amount - phoenix.club_cash_amount)
          end

          unless TEST
            phoenix_cc = PhoenixCreditCard.find_by_member_id_and_active(phoenix.uuid, true)

            new_phoenix_cc = PhoenixCreditCard.new 
            new_phoenix_cc.encrypted_number = member.encrypted_cc_number
            new_phoenix_cc.number = CREDIT_CARD_NULL if new_phoenix_cc.number.nil?
            new_phoenix_cc.expire_month = member.cc_month_exp
            new_phoenix_cc.expire_year = member.cc_year_exp
            new_phoenix_cc.member_id = phoenix.uuid

            if phoenix_cc.nil?
              @log.info "  * member ##{member.id} does not have Credit Card active"
              new_phoenix_cc.save!
            elsif phoenix_cc.encrypted_number != member.encrypted_cc_number or 
                  phoenix_cc.expire_month != member.cc_month_exp or 
                  phoenix_cc.expire_year != member.cc_year_exp

              phoenix_cc.active = false
              new_phoenix_cc.save!
              phoenix_cc.save!
              add_operation(Time.zone.now, new_phoenix_cc, "Credit card #{new_phoenix_cc.last_digits} added and set active.", nil)
            end
          end

          update_fulfillment(member, phoenix)

          member.update_attribute :imported_at, Time.now.utc

        rescue Exception => e
          @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          raise ActiveRecord::Rollback
        end
      end
      @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
    end
  end
end

# 2- import new members.
def add_new_members
  BillingMember.where(" imported_at IS NULL and is_prospect = false and LOCATE('@', email) != 0 " + 
  # " and id = 20243929300 " + # uncomment this line if you want to import a single member.
  " and (( phoenix_status = 'lapsed' and cancelled_at IS NOT NULL ) OR (phoenix_status != 'lapsed' and phoenix_status IS NOT NULL)) " +
  " and phoenix_status IS NOT NULL and member_since_date IS NOT NULL and phoenix_join_date IS NOT NULL ").find_in_batches do |group|
    group.each do |member| 
      tz = Time.now.utc
      PhoenixMember.transaction do 
        @log.info "  * processing member ##{member.id}"
        begin
          # validate if email already exist
          phoenix = PhoenixMember.find_by_email_and_club_id member.email_to_import, CLUB
          unless phoenix.nil?
            puts "Email #{member.email_to_import} already exists"
            exit
            next
          end

          phoenix = PhoenixMember.new 
          phoenix.club_id = CLUB
          phoenix.terms_of_membership_id = get_terms_of_membership_id(member.campaign_id)
          # do not load member if it does not have TOM set
          if phoenix.terms_of_membership_id.nil?
            puts "CDId #{member.campaign_id} does not exist or TOM is empty"
            exit
            next
          end
          phoenix.visible_id = member.id
          set_member_data(phoenix, member)
          next_bill_date = member.cs_next_bill_date
          phoenix.status = member.phoenix_status
          if member.phoenix_status == 'active'
            phoenix.bill_date = next_bill_date
            phoenix.next_retry_bill_date = next_bill_date
          elsif member.phoenix_status == 'provisional'
            phoenix.bill_date = next_bill_date
            phoenix.next_retry_bill_date = next_bill_date
          else
            phoenix.recycled_times = 0
            phoenix.cancel_date = member.cancelled_at
            phoenix.bill_date, phoenix.next_retry_bill_date = nil, nil
          end
          phoenix.created_by_id = get_agent
          phoenix.save!

          @member = phoenix
          add_operation(Time.now.utc, nil, "Member imported into phoenix!", nil)  

          if phoenix.status == "lapsed"
            load_cancellation(@member.cancel_date)
          end

          # create Club cash transaction.
          if member.club_cash_amount.to_f != 0.0
            update_club_cash(member.club_cash_amount.to_f)
          end

          # create CC
          phoenix_cc = PhoenixCreditCard.new 
          phoenix_cc.number = CREDIT_CARD_NULL
          unless TEST
            phoenix_cc.encrypted_number = member.encrypted_cc_number
          end
          phoenix_cc.expire_month = member.cc_month_exp
          phoenix_cc.expire_year = member.cc_year_exp
          phoenix_cc.member_id = phoenix.uuid
          phoenix_cc.save!

          add_fulfillment(member.fulfillment_kit, member.fulfillment_since_date, member.fulfillment_expire_date)
          add_product_fulfillment(member.has_fulfillment_product)
          add_enrollment_info(phoenix, member)

          member.update_attribute :imported_at, Time.now.utc
          print "."
        rescue Exception => e
          @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          raise ActiveRecord::Rollback
        end
      end
      @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
    end
  end
end


# 2- import new members.
def load_duplicated_emails
  BillingMember.where(" imported_at IS NULL and is_prospect = false and LOCATE('@', email) != 0 " + 
  # " and id = 20243929300 " + # uncomment this line if you want to import a single member.
  " and (( phoenix_status = 'lapsed' and cancelled_at IS NOT NULL ) OR (phoenix_status != 'lapsed' and phoenix_status IS NOT NULL)) " +
  " and phoenix_status IS NOT NULL and member_since_date IS NOT NULL and phoenix_join_date IS NOT NULL ").find_in_batches do |group|
    group.each do |member| 
      tz = Time.now.utc
      PhoenixMember.transaction do 
        @log.info "  * processing member ##{member.id}"
        begin
          # validate if email already exist
          phoenix = PhoenixMember.find_by_email_and_club_id member.email_to_import, CLUB
          if phoenix.nil?
            puts "Email #{member.email_to_import} does not exists"
            exit
            next
          end
          if phoenix.status == member.phoenix_status and phoenix.status == 'lapsed'
            update_member_when_duplicated_email(member, phoenix)
            member.update_attribute :imported_at, Time.now.utc
          end
          print "."
        rescue Exception => e
          @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          raise ActiveRecord::Rollback
        end
      end
      @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
    end
  end
end


# update_members

add_new_members

# => needs test
# load_duplicated_emails
