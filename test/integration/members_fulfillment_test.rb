require 'test_helper'

class MembersFulfillmentTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member(create_new_member = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)

    if create_new_member
	    @saved_member = FactoryGirl.create(:active_member, 
	      :club_id => @club.id, 
	      :terms_of_membership => @terms_of_membership_with_gateway,
	      :created_by => @admin_agent)

			@saved_member.reload
      @product = FactoryGirl.create(:product, :club_id => @club.id, :sku => 'kit-card')
      @fulfillment = FactoryGirl.create(:fulfillment, :member_id => @saved_member.id, :product_sku => 'kit-card')
		end

    sign_in_as(@admin_agent)
  end

  def create_member_throught_sloop(enrollment_info)
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @payment_gateway_configuration = FactoryGirl.create(:payment_gateway_configuration, :club_id => @club.id)
    create_member_by_sloop(@admin_agent, @member, @credit_card, enrollment_info, @terms_of_membership_with_gateway)
  end

  ###########################################################
  # TESTS
  ###########################################################

  # test "cancel member and check if not_processed fulfillments were updated to canceled" do
  #   setup_member
    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('not_processed')
  #     }
  #   end

  #   @saved_member.set_as_canceled!

  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('canceled')
  #     }
  #   end
  #   @fulfillment.reload
  #   assert_equal @fulfillment.status, 'canceled'
  # end

  # test "cancel member and check if processing fulfillments were updated to canceled" do
  #   setup_member
  #   @fulfillment.set_as_processing

  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('processing')
  #     }
  #   end

  #   @saved_member.set_as_canceled!

  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('canceled')
  #     }
  #   end
  #   @fulfillment.reload
  #   assert_equal @fulfillment.status, 'canceled'
  # end

  # test "cancel member and check if out_of_stock fulfillments were updated to canceled" do
  #   setup_member
  #   @fulfillment.set_as_out_of_stock
    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('out_of_stock')
  #     }
  #   end

  #   @saved_member.set_as_canceled!

  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('canceled')
  #     }
  #   end
  #   @fulfillment.reload
  #   assert_equal @fulfillment.status, 'canceled'
  # end

  # test "cancel member and check if undeliverable fulfillments were updated to canceled" do
  #   setup_member
  #   @fulfillment.set_as_processing
  #   @fulfillment.set_as_undeliverable
    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('undeliverable')
  #     }
  #   end

  #   @saved_member.set_as_canceled!

  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('canceled')
  #     }
  #   end
  #   @fulfillment.reload
  #   assert_equal @fulfillment.status, 'canceled'
  # end 

  # test "display 'Mark as sent' and 'Set as wrong number' when fulfillment is processing on memebr's profile." do
  #   setup_member
  #   @fulfillment.set_as_processing    

  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_selector?('#mark_as_sent')     
  #     }
  #   end

  #   click_link_or_button('mark_as_sent')

  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?("Fulfillment #{@fulfillment.product_sku} was set as sent.")    
  #     }
  #   end
  #   @fulfillment.reload
  #   assert_equal @fulfillment.status,'sent'
  # end

  # test "display 'resend' when fulfillment is out_of_stock on memebr's profile." do
  #   setup_member
  #   @fulfillment.set_as_out_of_stock    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_selector?('#resend')     
  #     }
  #   end

  #   click_link_or_button('Resend')

  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?("Fulfillment #{@fulfillment.product_sku} was marked to be delivered next time.")    
  #     }
  #   end
  #   @fulfillment.reload
  #   assert_equal @fulfillment.status,'not_processed'
  # end

  # test "display default initial and end dates on fulfillments index" do
  #   setup_member
  #   visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

  #   within("#fulfillments_table") do
  #     wait_until{
  #       assert find_field('initial_date_').value == "#{Date.today-1.week}"
  #       assert find_field('end_date_').value == "#{Date.today}"
  #     }
  #   end
  # end

  # test "enroll a member with product not available but it on the list at CS and recurrent false" do
  #   setup_member(false)
  #   @product = FactoryGirl.create(:product_without_recurrent, :club_id => @club.id)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

  #   assert_difference('Product.find(@product.id).stock',-1) do
  #     create_member_throught_sloop(enrollment_info)
  #   end
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, @product.sku)
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at, nil)
  #   assert_equal(fulfillment.status, 'not_processed')
    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{
  #     assert find_field('input_first_name').value == @saved_member.first_name
  #   }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
  #       assert page.has_content?(@product.sku)
  #       assert page.has_content?('not_processed')  
  #       assert page.has_no_selector?('Resend')
  #       assert page.has_no_selector?('Mark as sent')
  #       assert page.has_no_selector?('Set as wrong address')
  #     }
  #   end
  # end

  # test "enroll a member with product not available but it on the list at CS and recurrent true" do
  #   setup_member(false)
  #   @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

  #   assert_difference('Product.find(@product.id).stock',-1) do
  #     create_member_throught_sloop(enrollment_info)
  #   end
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.product_sku, @product.sku)
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at, fulfillment.assigned_at + 1.year)
  #   assert_equal(fulfillment.status, 'not_processed')
    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{
  #     assert find_field('input_first_name').value == @saved_member.first_name
  #   }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
  #       assert page.has_content?(I18n.l fulfillment.renewable_at, :format => :long)
  #       assert page.has_content?(@product.sku)
  #       assert page.has_content?('not_processed') 
  #       assert page.has_no_selector?('Resend')
  #       assert page.has_no_selector?('Mark as sent')
  #       assert page.has_no_selector?('Set as wrong address')
  #     }
  #   end
  # end

  # test "enroll a member with product out of stock and recurrent" do
  #   setup_member(false)
  #   @product = FactoryGirl.create(:product_without_stock_and_recurrent, :club_id => @club.id)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, @product.sku)
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at, fulfillment.assigned_at + 1.year)
  #   assert_equal(fulfillment.status, 'out_of_stock')
    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{
  #     assert find_field('input_first_name').value == @saved_member.first_name
  #   }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
  #       assert page.has_content?(I18n.l fulfillment.renewable_at, :format => :long)
  #       assert page.has_content?(@product.sku)
  #       assert page.has_content?('out_of_stock')  
  #       assert page.has_no_selector?('Resend')
  #       assert page.has_no_selector?('Mark as sent')
  #       assert page.has_no_selector?('Set as wrong address')
  #     }
  #   end
  # end

  # test "enroll a member with product out of stock and not recurrent" do
  #   setup_member(false)
  #   @product = FactoryGirl.create(:product_without_stock_and_not_recurrent, :club_id => @club.id)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, @product.sku)
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at, nil)
  #   assert_equal(fulfillment.status, 'out_of_stock')
    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{
  #     assert find_field('input_first_name').value == @saved_member.first_name
  #   }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
  #       assert page.has_content?(@product.sku)
  #       assert page.has_content?('out_of_stock')  
  #       assert page.has_no_selector?('Resend')
  #       assert page.has_no_selector?('Mark as sent')
  #       assert page.has_no_selector?('Set as wrong address')
  #     }
  #   end
  # end

  # test "enroll a member with product not in the list" do
  #   setup_member(false)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'product not in the list')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, 'product not in the list')
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at, nil)
  #   assert_equal(fulfillment.status, 'out_of_stock')
    
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{
  #     assert find_field('input_first_name').value == @saved_member.first_name
  #   }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
  #       assert page.has_content?('product not in the list')
  #       assert page.has_content?('out_of_stock')  
  #       assert page.has_no_selector?('Resend')
  #       assert page.has_no_selector?('Mark as sent')
  #       assert page.has_no_selector?('Set as wrong address')
  #     }
  #   end
  # end

  # test "enroll a member with blank product_sku" do
  #   setup_member(false)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => '')
  #   assert_difference('Fulfillment.count',0){
  #     create_member_throught_sloop(enrollment_info)
  #   }
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{
  #     assert find_field('input_first_name').value == @saved_member.first_name
  #   }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?('No fulfillments were found.')
  #     }
  #   end
  # end

  # # TODO: Complete test ... line 52
  # # test "fulfillment record at not_processed status - recurrent true" do
  # #   setup_member(false)
  # #   @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
  # #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

  # #   create_member_throught_sloop(enrollment_info)
  # #   sleep(1)
  # #   @saved_member = Member.find_by_email(@member.email)

  # #   fulfillment = Fulfillment.last
  # #   assert_equal(fulfillment.member_id, @saved_member.id)
  # #   assert_equal(fulfillment.product_sku, @product.sku)
  # #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  # #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  # #   assert_equal(fulfillment.renewable_at, @saved_member.join_date + 1.year)
  # #   assert_equal(fulfillment.recurrent, true)
  # #   assert_equal(fulfillment.status, 'not_processed')

  # #   click_link_or_button("My Clubs")
  # #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  # #   wait_until{page.has_content?("Fulfillments")}

  # #   within("#fulfillments_table")do
  # #     wait_until{
  # #       assert page.find_field('initial_date_')
  # #       assert page.find_field('end_date_')
  # #       assert page.find_field('status')
  # #       assert page.find_field('_all_times')    
  # #       assert page.find_field('product_type')  
  # #     }
  # #   end
  # # end

  # test "dislpay default data on fulfillments index" do
  #   setup_member(false)

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}

  #   within("#fulfillments_table")do
  #     wait_until{
  #       assert find_field('initial_date_').value == "#{Date.today-1.week}"
  #       assert find_field('end_date_').value == "#{Date.today}"
  #       assert page.find_field('status').value == 'not_processed'
  #       assert page.find_field('_all_times')   
  #       assert page.find_field('product_type')
  #     }
  #   end
  # end

  # test "fulfillment record at processing + check stock" do
  #   setup_member(false)
  #   @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)
  #   initial_stock = @product.stock
  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, @product.sku)
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at, @saved_member.join_date + 1.year)
  #   assert_equal(fulfillment.recurrent, true)
  #   assert_equal(fulfillment.status, 'not_processed')

  #   fulfillment.set_as_processing

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}

  #   within("#fulfillments_table")do
  #     wait_until{
  #       assert page.find_field('initial_date_')
  #       assert page.find_field('end_date_')
  #       assert page.find_field('status')
  #       assert page.find_field('_all_times')    
  #       assert page.find_field('product_type')  
  #     }
  #     check('_all_times')
  #     select('processing', :from => 'status')
  #     select('Others',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')

  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('processing') 
  #     }
  #   end

  #   @product.reload

  #   assert @product.stock == initial_stock-1
  # end

  # test "resend fulfillment with status sent and sku KIT" do
  #   setup_member(false)
  #   @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, 'KIT')
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at.year, @saved_member.join_date.year + 1)
  #   assert_equal(fulfillment.renewable_at.day, @saved_member.join_date.day)
  #   assert_equal(fulfillment.recurrent, true)
  #   assert_equal(fulfillment.status, 'not_processed')

  #   fulfillment.set_as_processing
  #   fulfillment.set_as_sent

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}

  #   within("#fulfillments_table")do
  #     wait_until{
  #       assert page.find_field('initial_date_')
  #       assert page.find_field('end_date_')
  #       assert page.find_field('status')
  #       assert page.find_field('_all_times')    
  #       assert page.find_field('product_type')  
  #     }
  #     check('_all_times')
  #     select('sent', :from => 'status')
  #     select('Kit',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')

  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('sent') 

  #       click_link_or_button("Resend")
  #       assert page.has_content?("Fulfillment KIT was marked to be delivered next time.")
  #     }
  #   end

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, 'KIT')
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at, @saved_member.join_date + 1.year)
  #   assert_equal(fulfillment.recurrent, true)
  #   assert_equal(fulfillment.status, 'not_processed')
  #   assert_equal(fulfillment.product.stock,98)
  # end

  # test "resend fulfillment with status sent and sku CARD" do
  #   setup_member(false)
  #   @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'CARD')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, 'CARD')
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at.year, @saved_member.join_date.year + 1)
  #   assert_equal(fulfillment.renewable_at.day, @saved_member.join_date.day)
  #   assert_equal(fulfillment.recurrent, true)
  #   assert_equal(fulfillment.status, 'not_processed')

  #   fulfillment.set_as_processing
  #   fulfillment.set_as_sent

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}

  #   within("#fulfillments_table")do
  #     wait_until{
  #       assert page.find_field('initial_date_')
  #       assert page.find_field('end_date_')
  #       assert page.find_field('status')
  #       assert page.find_field('_all_times')    
  #       assert page.find_field('product_type')  
  #     }
  #     check('_all_times')
  #     select('sent', :from => 'status')
  #     select('Card',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')

  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('sent') 

  #       click_link_or_button("Resend")
  #       assert page.has_content?("Fulfillment CARD was marked to be delivered next time.")
  #     }
  #   end

  #   fulfillment = Fulfillment.last
  #   assert_equal(fulfillment.member_id, @saved_member.id)
  #   assert_equal(fulfillment.product_sku, 'CARD')
  #   assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
  #   assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
  #   assert_equal(fulfillment.renewable_at, @saved_member.join_date + 1.year)
  #   assert_equal(fulfillment.recurrent, true)
  #   assert_equal(fulfillment.status, 'not_processed')
  #   assert_equal(fulfillment.product.stock,98)
  # end

  # test "fulfillment record at Processing" do
  #   setup_member(false)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   @saved_member.fulfillments.each do |fulfillment|
  #     fulfillment.set_as_processing
  #   end
  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}
  #   fulfillment = Fulfillment.find_by_product_sku('KIT')
  #   within("#fulfillments_table")do
  #     check('_all_times')
  #     select('processing', :from => 'status')
  #     select('Kit',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')
  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('processing') 
  #       assert page.has_selector?('#mark_as_sent')
  #       assert page.has_selector?('#set_as_wrong_address')

  #       click_link_or_button('Set as wrong address')
  #       wait_until{ page.has_selector?('#reason') }
  #       fill_in 'reason', :with => 'spam'
  #       confirm_ok_js
  #       click_link_or_button('Set wrong address')
  #       wait_until{ page.has_content?("#{fulfillment.member.full_address} is undeliverable. Reason: spam")}
  #     }
  #   end
  # end
  
  # test "mark sent fulfillment at processing status" do
  #   setup_member(false)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.find_by_product_sku('KIT')
  #   fulfillment.set_as_processing
  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}
  #   within("#fulfillments_table")do
  #     check('_all_times')
  #     select('processing', :from => 'status')
  #     select('Kit',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')
  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('processing') 
  #       assert page.has_selector?('#mark_as_sent')
  #       assert page.has_selector?('#set_as_wrong_address')

  #       click_link_or_button('Mark as sent')
  #       wait_until{ assert page.has_content?('Fulfillment KIT was set as sent.') }
  #     }
  #   end
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
  #       assert page.has_content?('KIT')
  #       assert page.has_content?('sent')  
  #     }
  #   end
  # end

  # test "set as wrong address fulfillment at processing status" do
  #   setup_member(false)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.find_by_product_sku('KIT')
  #   fulfillment.set_as_processing
  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}
  #   within("#fulfillments_table")do
  #     check('_all_times')
  #     select('processing', :from => 'status')
  #     select('Kit',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')
  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('processing') 
  #       assert page.has_selector?('#mark_as_sent')
  #       assert page.has_selector?('#set_as_wrong_address')

  #       click_link_or_button('Set as wrong address')
  #       wait_until{ page.has_selector?('#reason') }
  #       fill_in 'reason', :with => 'spam'
  #       confirm_ok_js
  #       click_link_or_button('Set wrong address')
  #       wait_until{ page.has_content?("#{fulfillment.member.full_address} is undeliverable. Reason: spam")}
  #     }
  #   end
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
  #       assert page.has_content?('KIT')
  #       assert page.has_content?('undeliverable')  
  #     }
  #   end
  # end

  # test "display fulfillment record at out_of_stock status" do
  #   setup_member(false)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.find_by_product_sku('KIT')
  #   fulfillment.set_as_out_of_stock
  #   product = fulfillment.product
  #   product.stock = 0
  #   product.save

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}
  #   within("#fulfillments_table")do
  #     check('_all_times')
  #     select('out_of_stock', :from => 'status')
  #     select('Kit',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')
  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('out_of_stock') 
  #       assert page.has_content?('Actual stock: 0.')
  #     }
  #   end
  # end

  # test "add stock and check fulfillment record with out_of_stock status" do
  #   setup_member(false)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.find_by_product_sku('KIT')
  #   fulfillment.set_as_out_of_stock
  #   product = fulfillment.product
  #   product.stock = 0
  #   product.save

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}
  #   within("#fulfillments_table")do
  #     check('_all_times')
  #     select('out_of_stock', :from => 'status')
  #     select('Kit',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')
  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('out_of_stock') 
  #       assert page.has_content?('Actual stock: 0.')
  #     }
  #   end
  #   visit products_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   within("#products_table")do
  #     wait_until{ click_link_or_button('Edit') }
  #   end
  #   wait_until{ page.has_content?('Edit Product') }
  #   fill_in 'product[stock]', :with => '10'
  #   click_link_or_button('Update Product')

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}
  #   within("#fulfillments_table")do
  #     check('_all_times')
  #     select('out_of_stock', :from => 'status')
  #     select('Kit',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')
  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('out_of_stock') 
  #       assert page.has_content?('Actual stock: 10.')
  #       assert page.has_selector?("#resend")
  #     }
  #   end
  # end

  # test "resend fulfillment - Product out of stock" do
  #   setup_member(false)
  #   enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

  #   create_member_throught_sloop(enrollment_info)
  #   sleep(1)
  #   @saved_member = Member.find_by_email(@member.email)

  #   fulfillment = Fulfillment.find_by_product_sku('KIT')
  #   fulfillment.set_as_out_of_stock
  #   product = fulfillment.product
  #   product.stock = 0
  #   product.save

  #   visit products_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   within("#products_table")do
  #     wait_until{ click_link_or_button('Edit') }
  #   end
  #   wait_until{ page.has_content?('Edit Product') }
  #   fill_in 'product[stock]', :with => '10'
  #   click_link_or_button('Update Product')

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}
  #   within("#fulfillments_table")do
  #     check('_all_times')
  #     select('out_of_stock', :from => 'status')
  #     select('Kit',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')
  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{fulfillment.member.visible_id}")
  #       assert page.has_content?(fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
  #       assert page.has_content?(fulfillment.product_sku)
  #       assert page.has_content?(fulfillment.tracking_code)
  #       assert page.has_content?('out_of_stock') 
  #       assert page.has_content?('Actual stock: 10.')
  #       assert page.has_selector?("#resend")
  #     }
  #     click_link_or_button('Resend')
  #     wait_until{ assert page.has_content?('Fulfillment KIT was marked to be delivered next time.') }
  #   end
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
  #       assert page.has_content?('KIT')
  #       assert page.has_content?('not_processed')  
  #     }
  #   end
  # end

  test "renewal as out_of_stock and set renewed when product does not have stock" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT')
    fulfillment.set_as_processing
    fulfillment.set_as_sent
    product = fulfillment.product
    product.stock = 0
    product.save

    fulfillment.renew!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?(I18n.l @saved_member.join_date + 1.year, :format => :long)
        assert page.has_content?('KIT')
        assert page.has_content?('out_of_stock')
        assert page.has_content?('sent')
      }
    end
    fulfillment.reload
    fulfillment_new = Fulfillment.last
    wait_until{
      assert_equal(fulfillment_new.product_sku, fulfillment.product_sku)
      assert_equal((I18n.l fulfillment_new.assigned_at, :format => :long), (I18n.l Date.today, :format => :long))
      assert_equal((I18n.l fulfillment_new.renewable_at, :format => :long), (I18n.l fulfillment_new.assigned_at + 1.year, :format => :long))
      assert_equal(fulfillment_new.status, 'out_of_stock')
      assert_equal(fulfillment_new.renewed, false)
      assert_equal(fulfillment.renewed, true)     
    }
  end

  test "renewal as undeliverable and set renewed" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT')
    fulfillment.set_as_processing
    fulfillment.member.set_wrong_address(@admin_agent,'spam')
    fulfillment.reload
    fulfillment.renew!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?(I18n.l @saved_member.join_date + 1.year, :format => :long)
        assert page.has_content?('KIT')
        assert page.has_content?('undeliverable')
      }
    end
    fulfillment.reload
    fulfillment_new = Fulfillment.last
    wait_until{
      assert_equal(fulfillment_new.product_sku, fulfillment.product_sku)
      assert_equal((I18n.l fulfillment_new.assigned_at, :format => :long), (I18n.l Date.today, :format => :long))
      assert_equal((I18n.l fulfillment_new.renewable_at, :format => :long), (I18n.l fulfillment_new.assigned_at + 1.year, :format => :long))
      assert_equal(fulfillment_new.status, 'undeliverable')
      assert_equal(fulfillment_new.renewed, false)
      assert_equal(fulfillment.renewed, true)     
    }
  end

end
