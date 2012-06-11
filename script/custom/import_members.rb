#!/bin/ruby

require_relative 'import_models'

def get_disposition_type_id(note_type_id, cid)
  return nil if note_type_id.nil?
  note_type = CustomerServicesNoteType.find(note_type_id)
  enum = PhoenixEnumeration.find_by_name_and_club_id_and_type(note_type.name, cid,'DispositionType')
  if enum.nil?
    enum = DispositionType.new
    enum.name = note_type.name
    enum.club_id = cid
    enum.visible = true
    enum.save!
  end
  enum.id
end
def get_communication_type_id(communication_id)
  return nil if communication_id.nil?
  note_type = CustomerServicesCommunication.find(communication_id)
  enum = PhoenixEnumeration.find_by_name_and_type(note_type.name,'CommunicationType')
  if enum.nil?
    enum = CommunicationType.new
    enum.name = note_type.name
    enum.visible = true
    enum.save!
  end
  enum.id
end


BillingMember.where("id > 20238246005").find_in_batches do |group|
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
      phoenix.email = member.email
      phoenix.email = "test#{member.id}@xagax.com"
      phoenix.address = member.address
      phoenix.city = member.city
      phoenix.state = member.state
      phoenix.zip = member.zip
      phoenix.country = 'US'
      if member.active
        phoenix.status = 'active'
        phoenix.bill_date = (member.next_bill_date rescue member.cs_next_bill_date)
        phoenix.next_retry_bill_date = (member.next_bill_date rescue member.cs_next_bill_date)
      elsif member.trial
        phoenix.status = 'provisional'
        phoenix.bill_date = (member.next_bill_date rescue member.cs_next_bill_date)
        phoenix.next_retry_bill_date = (member.next_bill_date rescue member.cs_next_bill_date)
      else
        phoenix.status = 'lapsed'
        phoenix.recycled_times = 0
        phoenix.cancel_date = (member.cancelled_at rescue member.updated_at)
      end
      phoenix.join_date = member.join_date
      phoenix.created_by_id = get_agent
      phoenix.quota = (member.quota rescue 0)
      phoenix.created_at = member.created_at
      phoenix.updated_at = member.updated_at
      phoenix.phone_number = member.phone
      phoenix.blacklisted = false # TODO: load this from new_members.blacklisted (new column)
      # phoenix.enrollment_info = { :prospect_token => member.prospect_token }
      phoenix.member_since_date = (member.member_since rescue member.created_at)
      phoenix.save!

      # phoenix.member_group_type_id
      # phoenix.reactivation_times
      # phoenix.api_id
      # phoenix.last_synced_at
      # phoenix.last_sync_error
      # phoenix.club_cash_amount
      # phoenix.recycled_times
      # `new_members`.`on_renew`,
      # `new_members`.`renewable`,

      # create CC
      phoenix_cc = PhoenixCreditCard.new 
      phoenix_cc.encrypted_number = (member.encrypted_primary_cc_number rescue member.encrypted_cc_number)
      if phoenix_cc.number.nil?
        phoenix_cc.number = "0000000000"
      end
      phoenix_cc.expire_month = (member.primary_cc_month_exp rescue member.cc_month_exp)
      phoenix_cc.expire_year = (member.primary_cc_year_exp rescue member.cc_year_exp)
      phoenix_cc.last_successful_bill_date = (member.last_charged_at rescue member.last_charged)
      phoenix_cc.member_id = phoenix.uuid
      phoenix_cc.last_digits = phoenix_cc.number.last(4)
      phoenix_cc.save!

      # load member notes
      notes = CustomerServicesNotes.find_all_by_source_id_and_source_type(member.id, 'Contact')
      notes.each do |note|
        phoenix_note = PhoenixMemberNote.new
        phoenix_note.member_id = phoenix.uuid
        phoenix_note.created_by_id = get_agent(note.author_id)
        phoenix_note.description = note.content
        phoenix_note.disposition_type_id = get_disposition_type_id(note.note_type_id, CLUB)
        phoenix_note.communication_type_id = get_communication_type_id(note.communication_id)
        phoenix_note.created_at = note.created_on
        phoenix_note.updated_at = note.updated_on
        phoenix_note.save!
        note.destroy
      end

      member.destroy
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      exit
    end
    @log.info "    ... took #{Time.now - tz} for member ##{member.id}"
  end
  sleep(5) # Make sure it doesn't get too crowded in there!
end
