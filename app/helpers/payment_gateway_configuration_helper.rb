module PaymentGatewayConfigurationHelper
	def generate_select_gateway(payment_gateway_configuration, current_payment_gateway=nil)
    available_gateways = Settings.payment_gateways.collect{|x| [I18n.t("activerecord.gateway.#{x}"),x]}
    available_gateways.delete([I18n.t("activerecord.gateway.#{current_payment_gateway.gateway}"),current_payment_gateway.gateway]) if current_payment_gateway and current_payment_gateway.gateway
    
    select_tag('payment_gateway_configuration[gateway]', options_for_select(available_gateways, payment_gateway_configuration.gateway), :class => 'select_field')
	end
end