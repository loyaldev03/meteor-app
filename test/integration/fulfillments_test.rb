require 'test_helper' 

class FulfillmentsTest < ActionController::IntegrationTest


  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
   
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  def setup_fulfillments_and_products

  end

  ############################################################
  # TESTS
  ############################################################

  test "Should show response when marking as sent" do
  	@fulfillment_without_stock = FactoryGirl.create(:fulfillment_without_stock_with_product_with_stock, :member_id => @member.id) 
  	@product= FactoryGirl.create(:product, :club_id => @club.id)

  	visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  	within ("#fulfillments_table") do
			select('out_of_stock', :from => '[status]')
			check('[all_times]')
	    click_link_or_button 'Report'

  	end

  	within ("#report_results") do
  		click_link_or_button 'Resend'
 	    sleep(2) #waiting for response.
  		assert page.has_content?("Fulfillment #{@fulfillment_without_stock.product_sku} was marked to be delivered next time.")
  	end
  end

  test "Should show response when setting undeliverable member's address" do
  	@fulfillment_processing = FactoryGirl.create(:fulfillment_processing, :member_id => @member.id) 
  	reason = 'spam'
  	visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  	within ("#fulfillments_table") do
			select('processing', :from => '[status]')
			check('[all_times]')
	    click_link_or_button 'Report'
  	end

  	within ("#report_results") do
  		click_link_or_button 'Set as wrong address'
  		fill_in 'reason', :with => reason
  		confirm_ok_js
  		click_link_or_button 'Set wrong address'

 	    sleep(2) #waiting for response.
  		assert page.has_content?("#{@fulfillment_processing.member.full_address} is undeliverable. Reason: #{reason}")
  	end
  end

end