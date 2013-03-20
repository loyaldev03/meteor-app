#!/bin/ruby

require './import_models'

@log = Logger.new('log/import_notes.log', 10, 1024000)
ActiveRecord::Base.logger = @log

@communication_types = CustomerServicesCommunication.all
@note_types = CustomerServicesNoteType.all

def get_disposition_type_id(note_type_id, cid)
  return nil if note_type_id.nil?
  note_type = @note_types.select {|s| s.id == note_type_id }
  enum = PhoenixEnumeration.find_by_name_and_club_id_and_type(note_type[0].name, cid,'DispositionType')
  if enum.nil?
    enum = DispositionType.new
    enum.name = note_type[0].name
    enum.club_id = cid
    enum.visible = true
    enum.save!
  end
  enum.id
end

def get_communication_type_id(communication_id)
  return nil if communication_id.nil?
  comm_type = @communication_types.select {|s| s.id == communication_id }
  enum = PhoenixEnumeration.find_by_name_and_type(comm_type[0].name,'CommunicationType')
  if enum.nil?
    enum = CommunicationType.new
    enum.name = comm_type[0].name
    enum.visible = true
    enum.save!
  end
  enum.id
end

def import_customer_notes
  CustomerServicesNotes.where("imported_at IS NULL").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |note| 
      begin
        # load member notes
        member = PhoenixMember.find_by_club_id_and_visible_id(CLUB, note.source_id)
        unless member.nil?
          @log.info "  * processing note ##{note.id}"
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
          print "."
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        #exit
        #return
      end
    end
  end
end


import_customer_notes
