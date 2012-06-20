#!/bin/ruby

require_relative 'import_models'

# 1- update existing members
BillingMember.where("imported_at IS NOT NULL AND updated_at > imported_at").find_in_batches do |group|
  group.each do |member| 
    tz = Time.now
    begin
      @log.info "  * processing member ##{member.id}"

      phoenix = PhoenixMember.find_by_club_id_and_visible_id(CLUB, member.id)
      if phoenix.nil?
        @log.info "  * member ##{member.id} not found on phoenix ?? "
      else
        #TODO: puede haber cambio de TOM  en ONMC production ?
        phoenix.first_name = member.first_name
        phoenix.last_name = member.last_name
        phoenix.email = (TEST ? "test#{member.id}@xagax.com" : member.email)
        phoenix.address = member.address
        phoenix.city = member.city
        phoenix.state = member.state
        phoenix.zip = member.zip
        phoenix.country = member.country
        phoenix.joint = member.joint
        
        next_bill_date = member.cs_next_bill_date
        if member.active
          phoenix.status = 'active'
          phoenix.bill_date = next_bill_date
          phoenix.next_retry_bill_date = next_bill_date
        elsif member.trial
          phoenix.status = 'provisional'
          phoenix.bill_date = next_bill_date
          phoenix.next_retry_bill_date = next_bill_date
        else
          phoenix.status = 'lapsed'
          phoenix.recycled_times = 0
          phoenix.cancel_date = member.cancelled_at
        end
        phoenix.join_date = member.join_date
        phoenix.created_by_id = get_agent
        phoenix.quota = member.quota
        phoenix.created_at = member.created_at
        phoenix.updated_at = member.updated_at
        phoenix.phone_number = member.phone
        phoenix.blacklisted = members.blacklisted
        phoenix.enrollment_info = { :mega_channel => members.mega_channel, 
          :product_id => members.product_id,
          :enrollment_amount => members.enrollment_amount_to_import,
          :reporting_code => members.reporting_code, 
          :tom_id => phoenix.terms_of_membership_id, 
          :prospect_token => member.prospect_token }
        phoenix.member_since_date = member.member_since_date
        phoenix.api_id = member.drupal_user_api_id
        phoenix.save!

        @member = phoenix

        if phoenix.status == "lapsed"
          load_cancellation
        end        

        if phoenix.club_cash_amount.to_f != member.club_cash_amount.to_f
          # create Club cash transaction.
          cct = ClubCashTransaction.new 
          cct.amount = (member.club_cash_amount - phoenix.club_cash_amount)
          cct.description = "Imported club cash transaction"
          cct.member_id = phoenix.uuid
          cct.save!
          add_operation(Time.zone.now, cct, "Imported club cash transaction. Amount: $#{cct.amount}", nil)
        end

        phoenix_cc = PhoenixCreditCard.find_by_member_id_and_active(phoenix.uuid, true)
        if phoenix_cc.nil?
          @log.info "  * member ##{member.id} does not have Credit Card active"
        elsif phoenix_cc.encrypted_number != member.encrypted_cc_number or 
              phoenix_cc.expire_month != member.cc_month_exp or 
              phoenix_cc.expire_year != member.cc_year_exp

          new_phoenix_cc = PhoenixCreditCard.new 
          new_phoenix_cc.encrypted_number = member.encrypted_cc_number
          if new_phoenix_cc.number.nil?
            new_phoenix_cc.number = "0000000000"
          end
          new_phoenix_cc.expire_month = member.cc_month_exp
          new_phoenix_cc.expire_year = member.cc_year_exp
          # phoenix_cc.last_successful_bill_date = member.last_charged
          new_phoenix_cc.member_id = phoenix.uuid

          if new_phoenix_cc.save! && phoenix_cc.deactivate
            add_operation(Time.zone.now, new_phoenix_cc, "Credit card #{new_phoenix_cc.last_digits} added and set active.", nil)
            member.update_attribute :imported_at, Time.zone.now
          end
        end
      end

    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      exit
    end
    @log.info "    ... took #{Time.now - tz} for member ##{member.id}"
  end
  sleep(5) # Make sure it doesn't get too crowded in there!
end


# 2- import new members.
# TODO: how do we avoid prospectS ????
BillingMember.where("imported_at IS NULL").find_in_batches do |group|
  group.each do |member| 
    tz = Time.now
    begin
      @log.info "  * processing member ##{member.id}"
      phoenix = PhoenixMember.new 
      phoenix.club_id = CLUB
      phoenix.terms_of_membership_id = get_terms_of_membership_id(member.campaign_id)
      phoenix.visible_id = member.id
      phoenix.first_name = member.first_name
      phoenix.last_name = member.last_name
      phoenix.email = (TEST ? "test#{member.id}@xagax.com" : member.email)
      phoenix.address = member.address
      phoenix.city = member.city
      phoenix.state = member.state
      phoenix.zip = member.zip
      phoenix.joint = member.joint
      phoenix.country = member.country
      next_bill_date = member.cs_next_bill_date
      if member.active
        phoenix.status = 'active'
        phoenix.bill_date = next_bill_date
        phoenix.next_retry_bill_date = next_bill_date
      elsif member.trial
        phoenix.status = 'provisional'
        phoenix.bill_date = next_bill_date
        phoenix.next_retry_bill_date = next_bill_date
      else
        phoenix.status = 'lapsed'
        phoenix.recycled_times = 0
        phoenix.cancel_date = member.cancelled_at
      end
      phoenix.join_date = member.join_date
      phoenix.created_by_id = get_agent
      phoenix.quota = member.quota
      phoenix.created_at = member.created_at
      phoenix.updated_at = member.updated_at
      phoenix.phone_number = member.phone
      phoenix.blacklisted = members.blacklisted
      phoenix.enrollment_info = { :mega_channel => members.mega_channel, 
        :product_id => members.product_id,
        :enrollment_amount => members.enrollment_amount_to_import,
        :reporting_code => members.reporting_code, 
        :tom_id => phoenix.terms_of_membership_id, 
        :prospect_token => member.prospect_token }
      phoenix.member_since_date = member.member_since_date
      phoenix.api_id = member.drupal_user_api_id
      phoenix.save!

      @member = phoenix

      if phoenix.status == "lapsed"
        load_cancellation
      end

      # phoenix.reactivation_times
      # phoenix.recycled_times
      # `new_members`.`on_renew`,
      # `new_members`.`renewable`,

      # create Club cash transaction.
      cct = ClubCashTransaction.new 
      cct.amount = member.club_cash_amount
      cct.description = "Imported club cash"
      cct.member_id = phoenix.uuid
      cct.save!
      add_operation(Time.zone.now, cct, "Imported club cash transaction!. Amount: $#{cct.amount}", nil, Time.zone.now, Time.zone.now)

      # create CC
      phoenix_cc = PhoenixCreditCard.new 
      phoenix_cc.encrypted_number = member.encrypted_cc_number
      if phoenix_cc.number.nil?
        phoenix_cc.number = "0000000000"
      end
      phoenix_cc.expire_month = member.cc_month_exp
      phoenix_cc.expire_year = member.cc_year_exp
      phoenix_cc.last_successful_bill_date = member.last_charged
      phoenix_cc.member_id = phoenix.uuid
      phoenix_cc.save!

      member.update_attribute :imported_at, Time.zone.now
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      exit
    end
    @log.info "    ... took #{Time.now - tz} for member ##{member.id}"
  end
  sleep(5) # Make sure it doesn't get too crowded in there!
end
