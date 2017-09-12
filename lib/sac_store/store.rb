module SacStore
  mattr_accessor :logger 

  VARIANTS_URL                  = '/api/phoenix/variants'
  VARIANT_URL                   = '/api/phoenix/variant'
  FULFILLMENT_ASSIGNATION_URL   = '/api/phoenix/notify_fulfillment'
  FULFILLMENT_CANCELLATION_URL  = '/api/phoenix/cancel_fulfillment'
  FULFILLMENT_SENT_URL          = '/api/phoenix/mark_as_fulfilled'



  def self.enable_integration!
    logger.info " ** Initializing SAC Store integration at #{I18n.l(Time.zone.now)}"

    require 'sac_store/models/club_extensions'
    require 'sac_store/models/product_extensions'
    require 'sac_store/models/fulfillment_extensions'
    require 'sac_store/models/transport_setting_extensions'
    require 'sac_store/models/product_model'
    require 'sac_store/models/fulfillment_model'
    require 'sac_store/controllers/products_controller_extensions'

    Club.send :include, SacStore::ClubExtensions
    Product.send :include, SacStore::ProductExtensions
    Fulfillment.send :include, SacStore::FulfillmentExtensions
    TransportSetting.send :include, SacStore::TransportSettingExtensions
    ProductsController.send :include, SacStore::ProductsControllerExtensions
    logger.info "  * extending Models at #{I18n.l(Time.current)}"
  end

  def self.client(store_url)
    Faraday.new( url: ( store_url ), ssl: { verify: true } ) do |builder|
      builder.request :json
      builder.response :mashify
      builder.response :json, :content_type => /\bjson$/
      builder.response :logger
      builder.adapter  Faraday.default_adapter
    end
  end
end