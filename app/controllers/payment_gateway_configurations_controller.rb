class PaymentGatewayConfigurationsController < ApplicationController
  before_filter :validate_club_presence

	def show
		@payment_gateway_configuration = PaymentGatewayConfiguration.find(params[:id])
    my_authorize! :show, PaymentGatewayConfiguration, @payment_gateway_configuration.club_id
	end

	def new
    my_authorize! :new, PaymentGatewayConfiguration, @current_club.id
		@payment_gateway_configuration = PaymentGatewayConfiguration.new
	end

	def create
		my_authorize! :create, PaymentGatewayConfiguration, @current_club.id
		@payment_gateway_configuration = PaymentGatewayConfiguration.new(params[:payment_gateway_configuration])
		@payment_gateway_configuration.club_id = @current_club.id
		success = false
		if @current_club.members_count.to_i == 0 and @current_club.users.count == 0
			PaymentGatewayConfiguration.transaction do 
				begin
					if @payment_gateway_configuration.valid?
						@current_club.payment_gateway_configurations.first.delete if @current_club.payment_gateway_configurations.first
						success = true if @payment_gateway_configuration.save!
					end
				rescue Exception => e
					raise ActiveRecord::Rollback
				end
			end
		else
			flash.now[:error] = I18n.t("error_messages.pgc_cannot_be_created_club_has_users")
		end

		if success 
			redirect_to payment_gateway_configuration_path(:id => @payment_gateway_configuration.id), :notice => "Payment Gateway Configuration created successfully."
		else
			render "new"
		end
	end

	def edit
		@payment_gateway_configuration = PaymentGatewayConfiguration.find(params[:id])
    my_authorize! :show, PaymentGatewayConfiguration, @payment_gateway_configuration.club_id
	end

	def update
		@payment_gateway_configuration = PaymentGatewayConfiguration.find(params[:id])
    my_authorize! :show, PaymentGatewayConfiguration, @payment_gateway_configuration.club_id
		
		cleanup_for_update!(params[:payment_gateway_configuration])
		if @payment_gateway_configuration.update_attributes(params[:payment_gateway_configuration])
			flash.now[:notice] = "Payment Gateway updated successfully"
			redirect_to payment_gateway_configuration_path, :notice => "Payment Gateway Configuration updated successfully."
		else
			render "edit"	
		end
	end

	def cleanup_for_update!(hash)
    if hash
      hash.delete(:password) if hash[:password].blank?
      hash.delete(:aus_password) if hash[:aus_password].blank?
    end
  end

end