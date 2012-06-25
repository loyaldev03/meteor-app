#!/bin/ruby

require_relative 'import_models'

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


# 1- update existing members
def update_members
  BillingMember.where("imported_at IS NOT NULL AND updated_at > imported_at and is_prospect = false and phoenix_status IS NOT NULL ").find_in_batches do |group|
    group.each do |member| 
      tz = Time.now.utc
      PhoenixProspect.transaction do 
        @log.info "  * processing member ##{member.id}"
        begin
          phoenix = PhoenixMember.find_by_club_id_and_visible_id(CLUB, member.id)
          if phoenix.nil?
            @log.info "  * member ##{member.id} not found on phoenix ?? "
          else
            @member = phoenix

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

            phoenix.bill_date = member.cs_next_bill_date
            phoenix.next_retry_bill_date = member.cs_next_bill_date
            if phoenix.status != "lapsed" and member.phoenix_status == "lapsed"
              load_cancellation
            end        
            phoenix.status = member.phoenix_status
            if member.phoenix_status == 'lapsed'
              phoenix.recycled_times = 0
              phoenix.cancel_date = member.cancelled_at
              phoenix.bill_date, phoenix.next_retry_bill_date = nil, nil
            end

            phoenix.join_date = member.join_date
            phoenix.quota = member.quota
            phoenix.created_at = member.created_at
            phoenix.updated_at = member.updated_at
            phoenix.phone_number = member.phone
            phoenix.blacklisted = member.blacklisted
            phoenix.enrollment_info = { :mega_channel => member.mega_channel, 
              :product_id => member.product_id,
              :enrollment_amount => member.enrollment_amount_to_import,
              :reporting_code => member.reporting_code, 
              :tom_id => phoenix.terms_of_membership_id, 
              :prospect_token => member.prospect_token }
            phoenix.member_since_date = member.member_since_date
            phoenix.api_id = member.drupal_user_api_id
            phoenix.save!


            if phoenix.status == "lapsed"
              load_cancellation
            end        

            if phoenix.club_cash_amount.to_f != member.club_cash_amount.to_f
              # create Club cash transaction.
              update_club_cash(member.club_cash_amount - phoenix.club_cash_amount)
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
                member.update_attribute :imported_at, Time.now.utc
              end
            end
          end

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

        rescue Exception => e
          @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          raise ActiveRecord::Rollback
        end
      end
      @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
    end
    sleep(5) # Make sure it doesn't get too crowded in there!
  end
end

# 2- import new members.
def add_new_members
  BillingMember.where("imported_at IS NULL and is_prospect = false and phoenix_status IS NOT NULL ").find_in_batches do |group|
    group.each do |member| 
      tz = Time.now.utc
      PhoenixProspect.transaction do 
        @log.info "  * processing member ##{member.id}"
        begin
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
          phoenix.join_date = member.join_date
          phoenix.created_by_id = get_agent
          phoenix.quota = member.quota
          phoenix.created_at = member.created_at
          phoenix.updated_at = member.updated_at
          phoenix.phone_number = member.phone
          phoenix.blacklisted = member.blacklisted
          phoenix.enrollment_info = { :mega_channel => member.mega_channel, 
            :product_id => member.product_id,
            :enrollment_amount => member.enrollment_amount_to_import,
            :reporting_code => member.reporting_code, 
            :tom_id => phoenix.terms_of_membership_id, 
            :prospect_token => member.prospect_token }
          phoenix.member_since_date = member.member_since_date
          phoenix.api_id = member.drupal_user_api_id
          phoenix.save!

          @member = phoenix

          if phoenix.status == "lapsed"
            load_cancellation
          end

          # create Club cash transaction.
          if member.club_cash_amount.to_f != 0.0
            update_club_cash(member.club_cash_amount.to_f)
          end

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

          add_fulfillment(member.fulfillment_kit, member.fulfillment_since_date, member.fulfillment_expire_date)

          member.update_attribute :imported_at, Time.now.utc
        rescue Exception => e
          @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          raise ActiveRecord::Rollback
        end
      end
      @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
    end
    sleep(2) # Make sure it doesn't get too crowded in there!
  end
end

update_members
add_new_members
