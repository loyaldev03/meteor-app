module SacStore
  class FulfillmentModel < Struct.new(:fulfillment)

    def notify_fulfillment_assignation
      unless fulfillment.store_id
        response = conn.post FULFILLMENT_ASSIGNATION_URL, { api_key: settings['api_token'], variant_id: fulfillment.product.store_id.to_s }
        result   = response.body
        fulfillment.sync_result = if is_request_successful(result)
          fulfillment.store_id = result.stock_movement_id
          Product.where(id: fulfillment.product_id).update_all "stock = #{result.current_stock}"
          'success'
        else
          handle_error_on_call(fulfillment, result, 'Fulfillment::NotifyFulfillmentAssignation')
        end
        fulfillment.save(validate: false)
      end
    rescue => e
      Auditory.report_issue("Fulfillment::NotifyFulfillmentAssignation", e, { fulfillment_id: fulfillment.id, club: fulfillment.club_id })
      fulfillment.update_attribute :sync_result, e.to_s
    end

    def notify_fulfillment_cancellation
      if fulfillment.store_id
        response = conn.post FULFILLMENT_CANCELLATION_URL, { api_key: settings['api_token'], stock_movement_id: fulfillment.store_id.to_s }
        result   = response.body
        fulfillment.sync_result = if is_request_successful(result)
          fulfillment.store_id = nil
          'success'
        else
          handle_error_on_call(fulfillment, result, 'Fulfillment::NotifyFulfillmentCancelation')
        end
        fulfillment.save(validate: false)
      end
    rescue => e
      Auditory.report_issue("Fulfillment::NotifyFulfillmentCancelation", e, { fulfillment_id: fulfillment.id, club: fulfillment.club_id })
      fulfillment.update_attribute :sync_result, e.to_s
    end

    def notify_fulfillment_send
      response = conn.post FULFILLMENT_SENT_URL, { api_key: settings['api_token'], stock_movement_id: fulfillment.store_id.to_s }
      result   = response.body
      fulfillment.sync_result = if is_request_successful(result) or (result and result.code == 400)
        'success'
      else
        handle_error_on_call(fulfillment, result, 'Fulfillment::NotifyFulfillmentSend')
      end
      fulfillment.save(validate: false)
    rescue => e
      Auditory.report_issue("Fulfillment::NotifyFulfillmentSend", e, { fulfillment_id: fulfillment.id, club: fulfillment.club_id })
      fulfillment.update_attribute :sync_result, e.to_s
    end

    private
      def is_request_successful(result)
        result and not result.is_a?(String) and result.success
      end
    
      def handle_error_on_call(fulfillment, result, method)
        message = result.is_a? String ? result : result.message
        Auditory.notify_pivotal_tracker(message, method, {fulfillment_id: fulfillment.id, club: fulfillment.club_id})
        message
      end

      def settings
        @settings ||= self.fulfillment.club.transport_settings.store_spree.first.settings
      end

      def conn
        @conn ||= SacStore.client(settings['url'])
      end
  end
end