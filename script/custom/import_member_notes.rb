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

def import_customer_notes
  CustomerServicesNotes.where("imported_at IS NULL").find_in_batches do |group|
    group.each do |note| 
      tz = Time.now.utc
      begin
        @log.info "  * processing note ##{note.id}"
        # load member notes
        member = PhoenixMember.find_by_club_id_and_visible_id(CLUB, note.source_id)
        unless member.nil?
          phoenix_note = PhoenixMemberNote.new
          phoenix_note.member_id = member
          phoenix_note.created_by_id = get_agent(note.author_id)
          phoenix_note.description = note.content
          phoenix_note.disposition_type_id = get_disposition_type_id(note.note_type_id, CLUB)
          phoenix_note.communication_type_id = get_communication_type_id(note.communication_id)
          phoenix_note.created_at = note.created_on
          phoenix_note.updated_at = note.updated_on
          phoenix_note.save!
          note.update_attribute :imported_at, Time.now.utc
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      @log.info "    ... took #{Time.now.utc - tz} for note ##{note.id}"
    end
    sleep(5) # Make sure it doesn't get too crowded in there!
  end
end


import_customer_notes