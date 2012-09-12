class MemberNotesController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence

  def new
    @member_note = MemberNote.new
    @disposition_types = DispositionType.find_all_by_club_id(@current_club.id)
    @communication_types = CommunicationType.all
  end

  def create 
    member_note = MemberNote.new(:description => params[:member_note][:description])
    member_note.communication_type_id = params[:member_note][:communication_type_id]
    member_note.disposition_type_id = params[:member_note][:disposition_type_id]
    member_note.communication_type_id = params[:member_note][:communication_type_id]
    member_note.created_by_id = @current_agent.id
    member_note.member_id = @current_member.id
    
    if member_note.save
      Auditory.audit(@current_agent, member_note, "Note added", @current_member)
      redirect_to show_member_path, notice: "The note was added successfuly"
    else
      render action: "new"
    end
  end
end
