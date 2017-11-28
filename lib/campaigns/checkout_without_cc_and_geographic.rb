class Checkout
  attr :campaign
  attr :prospect

  def initialize(campaign:)
    @campaign = campaign
  end

  def set_data(params)
    @prospect.first_name            = params[:first_name]
    @prospect.last_name             = params[:last_name]
    @prospect.address               = params[:address]
    @prospect.city                  = params[:city]
    @prospect.address               = params[:address]
    @prospect.state                 = (Carmen::Country.coded('US').subregions.named(params[:state]).code if params[:state]) rescue nil
    @prospect.email                 = params[:email].downcase.clean_up_typoed_email if params[:email]
    @prospect.zip                   = params[:zip]
    @prospect.country               = 'US'
    @prospect.birth_date            = ''
    @prospect.gender                = ''
    @prospect.type_of_phone_number  = ''
    if params[:phone]
      params[:phone]                = params[:phone].delete('^0-9')
      @prospect.phone_area_code     = params[:phone][0,3]
      @prospect.phone_local_number  = params[:phone][3,7]
      @prospect.phone_country_code  = 1
    end

    if @prospect.phone_area_code.to_s.empty? && @prospect.phone_local_number.to_s.empty?
      @prospect.phone_area_code     = 0
      @prospect.phone_local_number  = 0
      @prospect.phone_country_code  = 0
    end

    product = Product.find_by(sku: params[:product_sku].upcase) if params[:product_sku]
    if product
      @prospect.product_sku         = product.sku
      @prospect.product_description = product.name
    end

    @prospect.preferences           = {}
    params.select{|param| param.include? 'pref_'}.each do |key, value|
      preference = Preference.includes(:preference_group).find_by(id: value)
      next unless preference.present?
      key_parts = key.split('_', 2)
      pref_code = key_parts[1]
      if preference.preference_group.code == pref_code
        @prospect.preferences[pref_code] = preference.name
      end
    end

    if @prospect.new_record?
      @prospect.cookie_value          = ''
      @prospect.cookie_set            = ''
      @prospect.joint                 = ''
      @prospect.user_agent            = params[:user_agent].truncate(255)
      @prospect.ip_address            = params[:ip_address]
      @prospect.campaign              = @campaign
      @prospect.campaign_description  = @campaign.name
      @prospect.campaign_code         = @campaign.campaign_code
      if params[:referral_url]
        referral_url                  = URI.parse(params[:referral_url])
        @prospect.referral_host       = referral_url.host
        @prospect.referral_path       = referral_url.path.downcase.truncate(255)
        @prospect.referral_parameters = referral_url.query
      end
    end
  end

  def validate_data(params)
    errors = Hash.new { |h, k| h[k] = [] }
    [:first_name, :last_name, :address, :city, :state, :email].each do |field|
      errors[field] << 'is required' if @prospect.send(field).to_s.empty?
    end
    [:first_name, :last_name, :address, :city].each do |field|
      errors[field] << 'is too short (minimum is 2 characters)' if @prospect.send(field) and @prospect.send(field).size < 2
      errors[field] << 'is too long (maximum is 50 characters)' if @prospect.send(field) and @prospect.send(field).size > 50
      errors[field] << I18n.t("checkout.validation.#{field}_problem") if @prospect.send(field) and not /\A[_a-z0-9\-()\[\]\/.,'" ]+\z/i.match(@prospect.send(field))
    end
    errors[:email] << I18n.t("checkout.validation.email_problem") if @prospect.email and not /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$\z/i.match(@prospect.email)
    errors[:state] << I18n.t("checkout.validation.state_problem") if @prospect.state and not /\A[_a-z0-9\-()\[\]\/.,'" ]+\z/i.match(@prospect.state)
    errors[:zip]   << I18n.t("checkout.validation.zip_problem") if @prospect.zip and not /\A[0-9]{5}\z/i.match(@prospect.zip)
    errors[:phone] << I18n.t("checkout.validation.phone_problem") if not params[:phone].to_s.empty? and not /\A([0-9]{10})\z/i.match(params[:phone])
    @prospect.update_attribute :error_messages, errors
  end

  def find_or_create_prospect_by(params)
    prospect_params = params.with_indifferent_access
    @prospect       = prospect_params[:token].nil? ? Prospect.new : Prospect.where_token(prospect_params[:token])
    if @prospect
      set_data(prospect_params)
      validate_data(prospect_params)
    end
    @prospect
  end

end
