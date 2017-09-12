module SacStore
  module ClubExtensions

    def self.included(base)
      base.send :include, InstanceMethods
    end


    module InstanceMethods
      def import_products_data
        if not billing_enable
          { success: false, message: 'The Club is not enabled.' }
        elsif not store_transport_setting
          { success: false, message: 'The Club does not have the correct credentials configured.' }
        else
          begin
            new_products_count, success_count, page = 0, 0, 1
            store_id_list, unexpected_errors, errors = [], [], []
            while(store_products = fetch_store_products(page)).any?
              store_products.each do |store_product_data|
                begin
                  product = Product.find_or_create_by(store_id: store_product_data['id'], club_id: self.id)
                  is_new_product = product.new_record?
                  if product.store_product.import_data(store_product_data)
                    success_count += 1
                    new_products_count += 1 if is_new_product
                  else
                    errors << "Store Product **#{store_product_data['sku']}**: #{product.errors.messages.to_s}"
                  end
                  store_id_list << store_product_data['id']
                rescue Exception => e
                  unexpected_errors << "Store Product **#{store_product_data['sku']}**: #{e}"
                end
              end
              page += 1
            end

            (Product.where(club_id: self.id).pluck(:store_id).uniq - store_id_list).each do |store_id|
              if product_to_delete = Product.find_by(store_id: store_id, club_id: self.id)
                product_to_delete.delete
                CampaignProduct.where(product_id: product_to_delete.id).delete_all
              else
                errors << "Store Product **#{store_product_data['sku']}** Could not be deleted: Product does not exist."
              end
            end

            Auditory.management_stock_notification("Error while importing product/s from Store", "There have been errors during the importing process from Store for club #{self.name}. Details are below:", errors) if errors.any?
            Auditory.management_stock_notification("Error while importing product/s from Store", "There have been unexpected errors during the importing process from Store for club #{self.name}. Details are below:", unexpected_errors) if unexpected_errors.any?

            { success: (errors.empty? and unexpected_errors.empty?), new_products_count: new_products_count, success_count: success_count, error_count: errors.count + unexpected_errors.count }
          rescue Exception => e
            Auditory.report_issue("Products::ImportProductsData", e, { club: self.id })
            { success: false, message: I18n.t('error_messages.airbrake_error_message') }
          end
        end
      end
      
      private
        def store_transport_setting
          @store_transport_setting ||= transport_settings.store_spree.first
        end

        def settings
          @settings ||= transport_settings.store_spree.first.settings
        end

        def conn
          @conn ||= SacStore.client(settings[:url])
        end

        def fetch_store_products(page)
          response = conn.post VARIANTS_URL, { api_key: settings['api_token'], page: page }
          response.body.data
        rescue Exception => e
          Auditory.report_issue("Products::FetchStoreProducts", "Unable to fetch products. Error: #{e}", { club: self.id })
          []
        end
    end

  end
end