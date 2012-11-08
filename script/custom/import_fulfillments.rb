#!/bin/ruby

require 'import_models'

@log = Logger.new('log/import_members.log', 10, 1024000)
ActiveRecord::Base.logger = @log

return 

# TODO: missing development


# fulfillment load should be review.
def add_fulfillment(fulfillment_kit, fulfillment_since_date, fulfillment_expire_date)
  if not fulfillment_kit.nil? and not fulfillment_expire_date.nil? and not fulfillment_since_date.nil?
    phoenix_f = PhoenixFulfillment.new :product => fulfillment_kit
    phoenix_f.member_id = @member.uuid
    phoenix_f.assigned_at = convert_from_date_to_time(fulfillment_since_date)
    phoenix_f.renewable_at = convert_from_date_to_time(fulfillment_expire_date)
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
      phoenix_f.renewable_at = nil
      phoenix_f.save!  
    end
  end
end
def update_fulfillment(member, phoenix)
  phoenix_f = PhoenixFulfillment.find_by_member_id_and_product(phoenix.uuid, member.fulfillment_kit)
  if phoenix_f.nil?
    add_fulfillment(member.fulfillment_kit, member.fulfillment_since_date, member.fulfillment_expire_date)
  else
    phoenix_f.product = member.fulfillment_kit
    phoenix_f.assigned_at = convert_from_date_to_time(member.fulfillment_since_date)
    phoenix_f.delivered_at = convert_from_date_to_time(member.fulfillment_since_date)
    phoenix_f.renewable_at = convert_from_date_to_time(member.fulfillment_expire_date)
    phoenix_f.save! 
  end
  add_product_fulfillment(member.has_fulfillment_product)
end


Phoenix.where(" imported_at IS NULL and is_prospect = false and LOCATE('@', email) != 0 and campaign_id = #{cid} " + 
     # " and id <= 13771771004 " + # uncomment this line if you want to import a single member.
      " and (( phoenix_status = 'lapsed' and cancelled_at IS NOT NULL ) OR (phoenix_status != 'lapsed')) " +
      " and phoenix_status IS NOT NULL and member_since_date IS NOT NULL and phoenix_join_date IS NOT NULL ").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |member| 
      tz = Time.now.utc
      # transactions between databases does not work
      #PhoenixMember.transaction do 
      @log.info "  * processing member ##{member.id}"
      begin
        # validate if email already exist
        phoenix = PhoenixMember.find_by_email_and_club_id member.email_to_import, CLUB
        unless phoenix.nil?
          puts "Email #{member.email_to_import} already exists"
          #exit
          next
        end

        phoenix = PhoenixMember.new 
        phoenix.club_id = CLUB
        phoenix.terms_of_membership_id = tom_id
        phoenix.visible_id = member.id
        set_member_data(phoenix, member)
        next_bill_date = convert_from_date_to_time(member.cs_next_bill_date)
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
        phoenix.created_by_id = DEFAULT_CREATED_BY
        phoenix.save!

        @member = phoenix
        add_enrollment_info(phoenix, member, @campaign)
        add_operation(Time.now.utc, nil, nil, "Member imported into phoenix!", nil)  

        if phoenix.status == "lapsed"
          load_cancellation(@member.cancel_date)
        end

        # create CC
        phoenix_cc = PhoenixCreditCard.new 
        fill_credit_card(phoenix_cc, member, phoenix)
        phoenix_cc.save!

        # add_fulfillment(member.fulfillment_kit, member.fulfillment_since_date, member.fulfillment_expire_date)
        # add_product_fulfillment(member.has_fulfillment_product)

        member.update_attribute :imported_at, Time.now.utc
        print "."
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        raise ActiveRecord::Rollback
      end
      #end
      @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
    end
  end
end

