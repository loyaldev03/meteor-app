class MembersController < ApplicationController
  before_filter :validate_club_presence
  before_filter :setup_member, :only => [ :show ]

  def index
  end

  def show
    @operations = @member.operations.paginate(:page => params[:page], :order => "operation_date DESC")
  end

  def new
    @member = Member.new 
    @terms_of_membership = TermsOfMembership.where(:club_id => @current_club )
  end

  def edit
  end

  private
    def setup_member
      @member = Member.find_by_visible_id_and_club_id(params[:id], @current_club.id)
    end
end
