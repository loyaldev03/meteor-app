class MemberNotesController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence

  def new
    @member_note = MemberNote.new
    @disposition_type = DispositionType.find_by_club_id(@current_club.id)
    @communication_type = CommunicationType.all
  end

  def create 
    member_note = MemberNote.new(params[:member_note])
    member_note.created_by_id = @current_agent.id
    member_note.member_id = @current_member.id
    message = "Agent #{@current_agent.username} added a note."
    
    respond_to do |format|
      if member_note.save
        Auditory.audit(@current_agent, member_note, message, @current_member)
        format.html { redirect_to show_member_path, notice: "The note was added successfuly" }
        format.json { render json: @member_note, status: :created, location: @member_note }
      else
        format.html { render action: "new" }
        format.json { render json: @member_note.errors, status: :unprocessable_entity }
      end
    end
  end










end
