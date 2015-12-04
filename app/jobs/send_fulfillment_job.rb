class SendFulfillmentJob < ActiveJob::Base
  queue_as :fulfillments

  def fulfillments_products_to_send(user)
    user.current_membership.enrollment_info.product_sku ? user.current_membership.enrollment_info.product_sku.split(',') : []
  end

  def perform(user_id)
    # we always send fulfillment to new members or members that do not have 
    # opened fulfillments (meaning that previous fulfillments expired).
    user = User.find user_id
    if user.fulfillments.where_not_processed.empty?
      fulfillments = fulfillments_products_to_send(user)
      fulfillments.each do |sku|
        begin
          product = Product.find_by(sku: sku, club_id: user.club_id)
          f = Fulfillment.new product_sku: sku
          unless product.nil?
            f.product_package = product.package
            f.recurrent = product.recurrent 
          end
          f.user_id = user.id
          f.club_id = user.club_id
          f.save
        rescue Exception => e
          Auditory.report_issue(I18n.t("error_messages.fulfillments_decrease_stock_error"), e, { user: user.inspect, fulfillment: f, product: product})
        end
      end
    end
  end
end
