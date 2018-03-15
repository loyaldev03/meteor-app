namespace :products do
  desc "Sent current product status list."
  # This task should be run each day at 3 am ?
  task :send_product_list_email => :environment do
    begin
      Rails.logger = Logger.new("#{Rails.root}/log/products_send_product_list_email.log")
      Rails.logger.level = Logger.const_get(Settings.logger_level_for_tasks)
      ActiveRecord::Base.logger = Rails.logger
      tall = Time.zone.now
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting products:send_product_list_email rake task"
      Product.send_product_list_email([1,15])
    rescue Exception => e
      Auditory.report_issue("Products::SendProductList", e)
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run products:send_product_list_email task"
    end
  end

  desc "Import product's data from Store."
  task :import_products_data_from_store => [:environment, :setup_logger ] do
    begin
      tall = Time.zone.now
      base = Club.joins(:transport_settings).where(billing_enable: true).merge(TransportSetting.store_spree)
      base.each do |club|
        club.import_products_data
      end
    rescue Exception => e
      Auditory.report_issue("Products::ImportProductDataFromStore", e)
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run products:import_products_data_from_store task"
    end
  end
end

