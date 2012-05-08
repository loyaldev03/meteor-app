class MemberNotesController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence

  def new
    @member_note = MemberNote.new
    @disposition_type = DispositionType.find_by_club_id(@current_club.id)
    @communication_type = CommunicationType.all
  end

  def create 
    member_note = MembersNote.new(params[:member_notes])

    respond_to do |format|
      if member_note.save
        format.html { redirect_to show_member_path, notice: "The note was added." }
        format.json { render json: @member_note, status: :created, location: @member_note }
      else
        format.html { render action: "new" }
        format.json { render json: @member_note.errors, status: :unprocessable_entity }
      end
    end
  end










end
