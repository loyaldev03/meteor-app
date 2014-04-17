namespace :products do
  desc "Sent current product status list."
  # This task should be run each day at 3 am ?
  task :send_product_list_email => :environment do
    begin
      Rails.logger = Logger.new("#{Rails.root}/log/products_send_product_list_email.log")
      Rails.logger.level = Logger::DEBUG
      ActiveRecord::Base.logger = Rails.logger
      tall = Time.zone.now
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting products:send_product_list_email rake task"
      Product.send_product_list_email
    rescue Exception => e
      Auditory.report_issue("Products::SendProductList", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run products:send_product_list_email task"
    end
  end


end