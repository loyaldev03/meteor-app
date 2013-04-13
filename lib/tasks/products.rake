namespace :products do
  desc "Sent current product status list."
  # This task should be run each day at 3 am ?
  task :send_product_list_email => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/products_send_product_list_email.log")
    tall = Time.zone.now
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting products:send_product_list_email rake task"
    begin
      Product.send_product_list_email
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run products:send_product_list_email task"
    end
  end


end