module SacStore
  module ProductsControllerExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def import_product_data
        response = if params[:product_id]
          if product = Product.find_by(id: params[:product_id])
            my_authorize! :import_data, Product, product.club_id
            if product.store_product.import_data and product.errors.empty?
              { success: true, message: "Imported successfully data from Store for product #{product.name} - #{product.sku}." }
            else
              { success: false, message: "Couldn't import data related to the product. #{product.errors.messages}" }
            end
          else
            { success: false, message: "Product not found." }
          end
        else  
          { success: false, message: "Product ID not provided." }
        end

        render json: response
      end    
    end
  end
end