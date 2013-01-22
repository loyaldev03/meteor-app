namespace :products do
  desc "Sent current product status list."
  # This task should be run each day at 3 am ?
  task :send_product_list_email => :environment do
    tall = Time.zone.now
    begin
      product_xls = Product.generate_xls
      temp = Tempfile.new("posts.xlsx") 
      
      product_xls.serialize temp.path
      Notifier.product_list(temp).deliver!
      
      temp.close 
      temp.unlink
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end


end