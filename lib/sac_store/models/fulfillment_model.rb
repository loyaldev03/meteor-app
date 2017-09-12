module SacStore
  class FulfillmentModel < Struct.new(:fulfillment)

    def notify_fulfillment_assignation
      unless fulfillment.store_id
        response = conn.post FULFILLMENT_ASSIGNATION_URL, { api_key: settings['api_token'], variant_id: fulfillment.product.store_id.to_s }
        result   = response.body
        fulfillment.sync_result = if result and result.success
          fulfillment.store_id = result.stock_movement_id
          Product.where(id: fulfillment.product_id).update_all "stock = #{result.current_stock}"
          'success'
        else
          result.message
        end
        fulfillment.save(validate: false)
      end
    rescue => e
      Auditory.report_issue("Fulfillment::NotifyFulfillmentAssignation", "Unable to notify fulfillment assignation. Error: #{e}", { fulfillment_id: fulfillment.id, club: fulfillment.club_id })
      fulfillment.update_attribute :sync_result, e.to_s
    end

    def notify_fulfillment_cancellation
      if fulfillment.store_id
        response = conn.post FULFILLMENT_CANCELLATION_URL, { api_key: settings['api_token'], stock_movement_id: fulfillment.store_id.to_s }
        result   = response.body
        fulfillment.sync_result = if result and result.success
          fulfillment.store_id = nil
          'success'
        else
          Auditory.report_issue("Fulfillment::NotifyFulfillmentCancelation", "Unable to notify fulfillment cancellation. Error: #{result.message}", { fulfillment_id: fulfillment.id, club: fulfillment.club_id })
          result.message
        end
        fulfillment.save(validate: false)
      end
    rescue => e
      Auditory.report_issue("Fulfillment::NotifyFulfillmentCancelation", "Unable to notify fulfillment cancellation. Error: #{e}", { fulfillment_id: fulfillment.id, club: fulfillment.club_id })
      fulfillment.update_attribute :sync_result, e.to_s
    end

    def notify_fulfillment_send
      response = conn.post FULFILLMENT_SENT_URL, { api_key: settings['api_token'], stock_movement_id: fulfillment.store_id.to_s }
      result   = response.body
      fulfillment.sync_result = if result and (result.success or result.code == 400)
        'success'
      else
        result.message
      end
      fulfillment.save(validate: false)
    rescue => e
      Auditory.report_issue("Fulfillment::NotifyFulfillmentSend", "Unable to notify fulfillment send. Error: #{e}", { fulfillment_id: fulfillment.id, club: fulfillment.club_id })
      fulfillment.update_attribute :sync_result, e.to_s
    end

    private

      def settings
        @settings ||= self.fulfillment.club.transport_settings.store_spree.first.settings
      end

      def conn
        @conn ||= SacStore.client(settings['url'])
      end
  end
end