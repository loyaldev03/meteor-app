class TermsOfMembershipsController < ApplicationController
  before_filter :validate_club_presence

  def show
    @tom = TermsOfMembership.find(params[:id])
    my_authorize! :show, TermsOfMembership, @tom.club_id
    @email_templates = EmailTemplate.find_all_by_terms_of_membership_id(params[:id])
    @payment_gateway_configuration_development = PaymentGatewayConfiguration.find_by_club_id_and_mode(@current_club.id,'development')
    @payment_gateway_configuration_production = PaymentGatewayConfiguration.find_by_club_id_and_mode(@current_club.id,'production')
  end

end