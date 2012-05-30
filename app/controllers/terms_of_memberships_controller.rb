class TermsOfMembershipsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence


  def show
    @tom = TermsOfMembership.find(params[:id])
    @email_templates = EmailTemplate.find_all_by_terms_of_membership_id(params[:id])
  end

end