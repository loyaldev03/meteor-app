module SacStore
  class ProductModel < Struct.new(:product)

    def import_data(store_product_data = nil)
      store_product_data        ||= fetch_store_product(self.product.store_id)
      if store_product_data
        product.name             = store_product_data['name']
        product.sku              = store_product_data['sku']
        product.weight           = store_product_data['weight'].to_f
        product.allow_backorder  = store_product_data['campaigns_backorderable']
        product.store_id         = store_product_data['id']
        product.stock            = store_product_data['stock'].to_i
        product.image_url        = store_product_data['image_url']
        product.store_slug       = store_product_data['slug']
        product.save
      else
        false
      end
    end

    private

      def settings
        @settings ||= self.product.club.transport_settings.store_spree.first.settings
      end

      def validate_result(response)
        if response.status == 200 and response.body.data
          response.body.data
        elsif response.status == 200
          product.errors.add :store, response.body.message
          nil
        elsif [401, 301].include? response.status
          product.errors.add :store, I18n.t('error_messages.transport_setting_wrong_credentials')
          nil
        else
          Auditory.report_issue("Products::FetchStoreProduct", "Unable to fetch product.", { response: response.inspect })
          product.errors.add :store, I18n.t('error_messages.airbrake_error_message')
          nil
        end
      end

      def fetch_store_product(variant_id)
        conn     = SacStore.client(settings['url'])
        response = conn.post VARIANT_URL, { api_key: settings['api_token'], id: variant_id.to_s }
        validate_result response
      rescue Exception => e
        Auditory.report_issue("Products::FetchStoreProduct", "Unable to fetch product. Error: #{e}", { product_id: product.id, club: product.club_id })
        product.errors.add :store, e.to_s
        nil
      end

  end
end