class UserNotesController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_user_presence
  
  def new
    my_authorize! :manage, UserNote, @current_club.id
    @user_note = UserNote.new
    @disposition_types = DispositionType.find_all_by_club_id(@current_club.id)
    @communication_types = CommunicationType.all
  end

  def create 
    my_authorize! :manage, UserNote, @current_club.id
    user_note = UserNote.new(:description => params[:user_note][:description])
    user_note.communication_type_id = params[:user_note][:communication_type_id]
    user_note.disposition_type_id = params[:user_note][:disposition_type_id]
    user_note.communication_type_id = params[:user_note][:communication_type_id]
    user_note.created_by_id = @current_agent.id
    user_note.user_id = @current_user.id
    
    if user_note.save
      Auditory.audit(@current_agent, user_note, "Note added", @current_user, Settings.operation_types.note_added)
      redirect_to show_user_path, notice: "The note was added successfuly"
    else
      render action: "new"
    end
  end
end
