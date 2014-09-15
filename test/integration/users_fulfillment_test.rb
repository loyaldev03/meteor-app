require 'test_helper'

class MembersFulfillmentTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  def setup_user(create_new_user = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    
    @partner = @club.partner
    Time.zone = @club.time_zone

    @product = Product.find_by_sku 'KIT-CARD'

    if create_new_user
      @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent })
      @fulfillment = FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'kit-card', :club_id => @club.id)
    end

    sign_in_as(@admin_agent)
  end

  def create_user_throught_sloop(enrollment_info)
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    create_user_by_sloop(@admin_agent, @user, @credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.last
  end

  def generate_fulfillment_files(all_times = true, fulfillments = nil ,initial_date = nil, end_date = nil, status = 'not_processed', type = nil, validate = true)
    search_fulfillments(all_times,initial_date,end_date,'not_processed', type)
    within("#report_results")do
      assert page.has_selector?("#create_xls_file")
      if fulfillments.nil?
        check "fulfillment_select_all"
      else 
        fulfillments.each do |fulfillment|
          check "fulfillment_selected[#{fulfillment.id}]"
        end
      end
      click_link_or_button 'Create XLS File'
    end
    if validate 
      assert page.has_content?("File created succesfully.")
      fulfillment_file = FulfillmentFile.last
      visit list_fulfillment_files_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
      
      within("#fulfillment_files_table") do
        assert page.has_content?(fulfillment_file.id.to_s)
        assert page.has_content?(fulfillment_file.status)
        assert page.has_content?(fulfillment_file.product)
        assert page.has_content?(fulfillment_file.dates)
        assert page.has_content?(fulfillment_file.fulfillments_processed)
        assert page.has_selector?("#mark_as_sent") if fulfillment_file.status == 'in_process'
        assert page.has_selector?("#download_xls_#{fulfillment_file.id}")
        click_link_or_button 'View'
      end

      # See "export all to xls" button at fulfillment file
      within("#report_results"){ assert page.has_selector?("#export_all_to_xls_btn") }

      fulfillments.each do |fulfillment| 
        fulfillment.reload
        assert_equal fulfillment.status, 'in_process'
      end

      assert_equal fulfillments.count, fulfillment_file.fulfillments.count
    end

  end

  ###########################################################
  # TESTS
  ###########################################################

  test "cancel user and check if in_process fulfillments were updated to canceled" do
    setup_user
    @fulfillment.set_as_in_process

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?('in_process')
    end

    @saved_user.set_as_canceled!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?('canceled')
    end
    @fulfillment.reload
    assert_equal @fulfillment.status, 'canceled'
  end

  test "cancel user and check if out_of_stock fulfillments were updated to canceled" do
    setup_user
    @fulfillment.set_as_out_of_stock
    
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?('out_of_stock')
    end

    @saved_user.set_as_canceled!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?('canceled')
    end
    @fulfillment.reload
    assert_equal @fulfillment.status, 'canceled'
  end

  test "cancel user and check if bad_address fulfillments were updated to canceled" do
    setup_user
    @fulfillment.set_as_in_process
    @fulfillment.set_as_bad_address
    
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?('bad_address')
    end

    @saved_user.set_as_canceled!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?('canceled')
    end
    @fulfillment.reload
    assert_equal @fulfillment.status, 'canceled'
  end 

  test "display default initial and end dates on fulfillments index" do
    setup_user
    visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

    within("#fulfillments_table") do
      assert find_field('initial_date').value == "#{Date.today-1.week}"
      assert find_field('end_date').value == "#{Date.today}"
    end
  end

  test "enroll an user with product not available but it on the list at CS and recurrent false" do
    setup_user(false)
    @product = FactoryGirl.create(:product_without_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    assert_difference('Product.find(@product.id).stock',-1) do
      create_user_throught_sloop(enrollment_info)
    end
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.user_id, @saved_user.id)
    assert_equal(fulfillment.product_sku, @product.sku)
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, nil)
    assert_equal(fulfillment.status, 'not_processed')
    
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(I18n.l @saved_user.join_date, :format => :only_date)
      assert page.has_content?(@product.sku)
      assert page.has_content?('not_processed')  
      assert page.has_no_selector?('Resend')
      assert page.has_no_selector?('Mark as sent')
      assert page.has_no_selector?('Set as wrong address')
    end
  end

  test "enroll an user with product not available but it on the list at CS and recurrent true" do
    setup_user(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    assert_difference('Product.find(@product.id).stock',-1) do
      create_user_throught_sloop(enrollment_info)
    end
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.product_sku, @product.sku)
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, fulfillment.assigned_at + 1.year)
    assert_equal(fulfillment.status, 'not_processed')
    
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(I18n.l @saved_user.join_date, :format => :only_date)
      assert page.has_content?(I18n.l fulfillment.renewable_at, :format => :only_date)
      assert page.has_content?(@product.sku)
      assert page.has_content?('not_processed') 
      assert page.has_no_selector?('Resend')
      assert page.has_no_selector?('Mark as sent')
      assert page.has_no_selector?('Set as wrong address')
    end
  end

  test "enroll an user with product out of stock and recurrent" do
    setup_user(false)
    @product = FactoryGirl.create(:product_without_stock_and_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_user_throught_sloop(enrollment_info)
    assert_nil User.find_by_email(@user.email)
  end

  test "enroll an user with product out of stock and not recurrent" do
    setup_user(false)
    @product = FactoryGirl.create(:product_without_stock_and_not_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_user_throught_sloop(enrollment_info)
    assert_nil User.find_by_email(@user.email)
  end

  test "enroll an user with product not in the list" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'product not in the list')

    create_user_throught_sloop(enrollment_info)
    assert_nil User.find_by_email(@user.email)
  end

  test "enroll an user with blank product_sku" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => '')
    assert_difference('Fulfillment.count',0){
      create_user_throught_sloop(enrollment_info)
    }
    @saved_user = User.find_by_email(@user.email)

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?('No fulfillments were found.')
    end
  end

  test "Enroll an user with recurrent product and it on the list" do
    setup_user(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)
    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.last

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")

    within("#fulfillments_table")do
      check('all_times')
      select('not_processed', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')

    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_no_selector?('#resend')
    end
    stock = @product.stock
    @product.reload
    assert_equal(@product.stock,stock-1)
  end

  test "display default data on fulfillments index" do
    setup_user(false)

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")

    within("#fulfillments_table")do
      assert find_field('initial_date').value == "#{Date.today-1.week}"
      assert find_field('end_date').value == "#{Date.today}"
      assert page.find_field('status').value == 'not_processed'
      assert page.find_field('all_times')   
    end
  end

  test "fulfillment record at in_process + check stock" do
    setup_user(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)
    initial_stock = @product.stock
    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.user_id, @saved_user.id)
    assert_equal(fulfillment.product_sku, @product.sku)
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, @saved_user.join_date + 1.year)
    assert_equal(fulfillment.recurrent, true)
    assert_equal(fulfillment.status, 'not_processed')

    fulfillment.set_as_in_process

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")

    within("#fulfillments_table")do
      assert page.find_field('initial_date')
      assert page.find_field('end_date')
      assert page.find_field('status')
      assert page.find_field('all_times')    
      check('all_times')
      select('in_process', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')

    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('in_process')
    end

    @product.reload

    assert @product.stock == initial_stock-1
  end

  test "resend KIT-CARD product with status = sent" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT-CARD')

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.user_id, @saved_user.id)
    assert_equal(fulfillment.product_sku, 'KIT-CARD')
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at.year, @saved_user.join_date.year + 1)
    assert_equal(fulfillment.renewable_at.day, @saved_user.join_date.day)
    assert_equal(fulfillment.recurrent, true)
    assert_equal(fulfillment.status, 'not_processed')

    fulfillment.set_as_in_process
    fulfillment.set_as_sent

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")

    within("#fulfillments_table")do
      assert page.find_field('initial_date')
      assert page.find_field('end_date')
      assert page.find_field('status')
      assert page.find_field('all_times')    
      check('all_times')
      select('sent', :from => 'status')
      choose('#radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')

    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('sent') 

      click_link_or_button("Resend")
      assert page.has_content?("Fulfillment KIT-CARD was marked to be delivered next time.")
    end
    fulfillment = Fulfillment.last
    assert_equal(fulfillment.user_id, @saved_user.id)
    assert_equal(fulfillment.product_sku, 'KIT-CARD')
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, @saved_user.join_date + 1.year)
    assert_equal(fulfillment.recurrent, true)
    assert_equal(fulfillment.status, 'not_processed')
    assert_equal(fulfillment.product.stock,98)
  end


  test "fulfillment record at Processing" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT-CARD')

    create_user_throught_sloop(enrollment_info)
    
    @saved_user = User.find_by_email(@user.email)

    @saved_user.fulfillments.each do |fulfillment|
      fulfillment.set_as_in_process
    end
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    fulfillment = Fulfillment.find_by_product_sku('KIT-CARD')
    within("#fulfillments_table")do
      check('all_times')
      select('in_process', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('in_process') 
      assert page.has_selector?('#mark_as_sent')
      assert page.has_selector?('#set_as_wrong_address')

      click_link_or_button('Set as wrong address')
      page.has_selector?('#reason')
      fill_in 'reason', :with => 'spam'
      confirm_ok_js
      click_link_or_button('Set wrong address')
      page.has_content?("#{fulfillment.user.full_address} is bad_address. Reason: spam")
    end
  end
  
  test "mark sent fulfillment at in_process status" do
    setup_user(false)
    product = FactoryGirl.create(:product, :club_id => @club.id, :recurrent => true)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.find_by_product_sku(@product.sku)
    fulfillment.set_as_in_process
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('in_process', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('in_process') 
      assert page.has_selector?('#mark_as_sent')
      assert page.has_selector?('#set_as_wrong_address')

      click_link_or_button('Mark as sent')
      assert page.has_content?("Fulfillment #{@product.sku} was set as sent.")
    end
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(I18n.l @saved_user.join_date, :format => :only_date)
      assert page.has_content?(@product.sku)
      assert page.has_content?('sent')
    end
  end

  test "set as wrong address fulfillment at in_process status" do
    setup_user(false)

    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT-CARD')

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT-CARD')
    fulfillment.set_as_in_process
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('in_process', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('in_process') 
      assert page.has_selector?('#mark_as_sent')
      assert page.has_selector?('#set_as_wrong_address')

      click_link_or_button('Set as wrong address')
      page.has_selector?('#reason')
      fill_in 'reason', :with => 'spam'
      confirm_ok_js
      click_link_or_button('Set wrong address')
      page.has_content?("#{fulfillment.user.full_address} is bad_address. Reason: spam")
    end
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(I18n.l @saved_user.join_date, :format => :only_date)
      assert page.has_content?('KIT-CARD')
      assert page.has_content?('bad_address')
    end
  end

  test "display fulfillment record at out_of_stock status" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT-CARD')

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT-CARD')
    fulfillment.set_as_out_of_stock
    product = fulfillment.product
    product.stock = 0
    product.save

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('out_of_stock', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('out_of_stock') 
      assert page.has_content?('Actual stock: 0.')
    end
  end

  test "add stock and check fulfillment record with out_of_stock status" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT-CARD')

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT-CARD')
    fulfillment.set_as_out_of_stock
    product = fulfillment.product
    product.stock = 0
    product.save

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('out_of_stock', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('out_of_stock') 
      assert page.has_content?('Actual stock: 0.')
    end
    visit products_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#products_table") do 
      within("tr", :text => product.name) do 
        click_link_or_button 'Edit'
      end
    end   

    page.has_content?('Edit Product')
    fill_in 'product[stock]', :with => '10'
    click_link_or_button('Update Product')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('out_of_stock', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('out_of_stock') 
      assert page.has_content?('Actual stock: 10.')
      assert page.has_selector?("#resend")
    end
  end

  test "resend fulfillment - Product out of stock" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT-CARD')

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT-CARD')
    fulfillment.set_as_out_of_stock
    product = fulfillment.product
    product.stock = 0
    product.save

    visit products_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

    within("#products_table") do 
      within("tr", :text => product.name) do 
        click_link_or_button 'Edit'
      end
    end    

    page.has_content?('Edit Product')
    fill_in 'product[stock]', :with => '10'
    click_link_or_button('Update Product')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('out_of_stock', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('out_of_stock') 
      assert page.has_content?('Actual stock: 10.')
      assert page.has_selector?("#resend")
      click_link_or_button('Resend')
      assert page.has_content?('Fulfillment KIT was marked to be delivered next time.')
    end
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(I18n.l @saved_user.join_date, :format => :only_date)
      assert page.has_content?('KIT-CARD')
      assert page.has_content?('not_processed')
    end
  end

  test "renewal as out_of_stock and set renewed when product does not have stock" do
    setup_user(false)
    product = FactoryGirl.create(:product, :recurrent => true, :club_id => @club.id )
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku)

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    @saved_user.set_as_active
    @saved_user.update_attribute(:recycled_times,0)
    @saved_user.current_membership.update_attribute(:join_date,Time.zone.now-1.year)


    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    fulfillment.set_as_in_process
    fulfillment.set_as_sent
    product = fulfillment.product
    product.update_attribute(:stock, 0)
    assert_equal(product.stock, 0)
    fulfillment.renew!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(I18n.l @saved_user.join_date + 1.year, :format => :only_date)
      assert page.has_content?(I18n.l @saved_user.join_date + 2.year, :format => :only_date)
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?('out_of_stock')
      assert page.has_content?('sent')
    end
    fulfillment.reload
    fulfillment_new = Fulfillment.last
    assert_equal(fulfillment_new.product_sku, fulfillment.product_sku)
    assert_equal((I18n.l fulfillment_new.assigned_at, :format => :only_date), (I18n.l Time.zone.now, :format => :only_date))
    assert_equal((I18n.l fulfillment_new.renewable_at, :format => :only_date), (I18n.l fulfillment_new.assigned_at + 1.year, :format => :only_date))
    assert_equal(fulfillment_new.status, 'out_of_stock')
    assert_equal(fulfillment_new.renewed, false)
    assert_equal(fulfillment.renewed, true)
  end

  test "renewal as bad_address and set renewed" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT-CARD')

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    @saved_user.set_as_active
    @saved_user.update_attribute(:recycled_times,0)
    @saved_user.current_membership.update_attribute(:join_date,Time.zone.now-1.year)

    fulfillment = Fulfillment.find_by_product_sku('KIT-CARD')
    fulfillment.set_as_in_process
    fulfillment.user.set_wrong_address(@admin_agent,'spam')
    fulfillment.reload
    fulfillment.renew!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(I18n.l @saved_user.join_date + 1.year, :format => :only_date)
      assert page.has_content?(I18n.l @saved_user.join_date + 2.year, :format => :only_date)
      assert page.has_content?('KIT-CARD')
      assert page.has_content?('bad_address')
    end
    fulfillment.reload
    fulfillment_new = Fulfillment.last
    assert_equal(fulfillment_new.product_sku, fulfillment.product_sku)
    assert_equal((I18n.l fulfillment_new.assigned_at, :format => :only_date), (I18n.l Time.zone.now, :format => :only_date))
    assert_equal((I18n.l fulfillment_new.renewable_at, :format => :only_date), (I18n.l fulfillment_new.assigned_at + 1.year, :format => :only_date))
    assert_equal(fulfillment_new.status, 'bad_address')
    assert_equal(fulfillment_new.renewed, false)
    assert_equal(fulfillment.renewed, true)
  end

  test "renewed 'sent' fulfillment should not show resend." do
    setup_user(false)
    product = FactoryGirl.create(:product, :recurrent => true, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku )

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    @saved_user.set_as_active
    @saved_user.current_membership.update_attribute(:join_date,Time.zone.now-1.year)  

    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    fulfillment.set_as_in_process
    fulfillment.set_as_sent
    
    fulfillment.renew!

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('sent', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end

    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('sent')
      assert page.has_content?('Renewed')
      assert page.has_no_selector?('#resend')
    end
  end

  test "fulfillment status bad_address" do
    setup_user

    @fulfillment.set_as_in_process
    @saved_user.set_wrong_address(@admin_agent, 'admin')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('bad_address', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')
    @fulfillment.reload
    within("#report_results")do
      assert page.has_content?("#{@fulfillment.user.id}")
      assert page.has_content?(@fulfillment.user.full_name)
      assert page.has_content?((I18n.l(@fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?(@fulfillment.tracking_code)
      assert page.has_content?('bad_address')
    end
  end

  test "Resend fulfillment with status bad_address - Product with stock" do
    setup_user

    @fulfillment.set_as_in_process
    @saved_user.set_wrong_address(@admin_agent, 'admin')
    @fulfillment.reload
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('bad_address', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')
    
    within("#report_results")do
      assert page.has_content?(@fulfillment.user.id.to_s)
      assert page.has_content?(@fulfillment.user.full_name)
      assert page.has_content?((I18n.l(@fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?(@fulfillment.tracking_code)
      assert page.has_content?('bad_address')
      click_link_or_button('This address is bad_address.')
    end
    click_link_or_button 'Edit'

    within("#table_demographic_information")do
      check('setter_wrong_address')
    end
    alert_ok_js
    click_link_or_button 'Update User'
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('not_processed')
    end
  end

  test "resend fulfillment with status bad_address - Product without stock" do
    setup_user(false)
    product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)

    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku )
    create_user_throught_sloop(enrollment_info)

    @saved_user = User.find_by_email(@user.email)
    @fulfillment = Fulfillment.first

    @fulfillment.set_as_in_process
    @saved_user.set_wrong_address(@admin_agent, 'admin')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('bad_address', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')
    @fulfillment.reload
    within("#report_results")do
      assert page.has_content?("#{@fulfillment.user.id}")
      assert page.has_content?(@fulfillment.user.full_name)
      assert page.has_content?((I18n.l(@fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?(@fulfillment.tracking_code)
      assert page.has_content?('bad_address')
      click_link_or_button('This address is bad_address.')
    end
    product.update_attribute(:stock,0)

    click_link_or_button 'Edit'

    within("#table_demographic_information")do
      check('setter_wrong_address')
    end
    alert_ok_js
    click_link_or_button 'Update User'
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('out_of_stock')
    end
  end

  test "fulfillment record from not_processed to cancel status" do
    setup_user

    @saved_user.set_as_canceled
    @saved_user.reload
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within("#table_membership_information")do
      assert page.has_content?('lapsed')
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('canceled')
    end
  end

  test "fulfillment record from in_process to cancel status" do
    setup_user
    @fulfillment.set_as_in_process

    @saved_user.set_as_canceled
    @saved_user.reload
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within("#table_membership_information")do 
      assert page.has_content?('lapsed')
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('canceled')
    end
  end

  test "fulfillment record from out_of_stock to cancel status" do
    setup_user
    @fulfillment.set_as_out_of_stock

    @saved_user.set_as_canceled
    @saved_user.reload
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within("#table_membership_information")do
      assert page.has_content?('lapsed')
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('canceled')
    end
  end

  test "fulfillment record from bad_address to cancel status" do
    setup_user
    @fulfillment.set_as_in_process
    @saved_user.set_wrong_address(@admin_agent, 'admin')
    @fulfillment.reload
    assert_equal(@fulfillment.status, 'bad_address')
    @saved_user.set_as_canceled
    @saved_user.reload
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within("#table_membership_information")do
      assert page.has_content?('lapsed')
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('canceled')
    end
  end

  test "fulfillment record at sent status when user is canceled" do
    setup_user

    @fulfillment.set_as_in_process
    @fulfillment.set_as_sent
    assert_equal(@fulfillment.status, 'sent')
    @saved_user.set_as_canceled
    @saved_user.reload
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within("#table_membership_information")do
      assert page.has_content?('lapsed')
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('sent')
    end
  end

  test "Fulfillments to be renewable with status canceled" do
    setup_user
    @product_recurrent = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    @fulfillment_renewable = FactoryGirl.create(:fulfillment, :product_sku => @product_recurrent.sku, :user_id => @saved_user.id, :club_id => @club.id)

    @fulfillment_renewable.set_as_canceled
    @fulfillment_renewable.reload

    TasksHelpers.process_fulfillments_up_today
    @fulfillment.reload

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(@fulfillment_renewable.product_sku)
      assert page.has_content?('canceled')
    end
    @fulfillment_renewable.reload
    assert_equal(@fulfillment_renewable.renewed,false)
  end

  test "resend fulfillment" do
    setup_user
    @fulfillment.set_as_out_of_stock

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?('out_of_stock')
        click_link_or_button 'Resend'
        page.has_content?("Fulfillment #{@fulfillment.product_sku} was marked to be delivered next time.")
        assert_equal(Operation.last.description, "Fulfillment #{@fulfillment.product_sku} was marked to be delivered next time.")
    end
  end

  test "fulfillments to be renewable with status sent" do
    setup_user
    @product_recurrent = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    @fulfillment_renewable = FactoryGirl.create(:fulfillment, :product_sku => @product_recurrent.sku, :user_id => @saved_user.id, :recurrent => true, :club_id => @club.id)
    @fulfillment_renewable.update_attribute(:renewable_at, Time.zone.now)
    @fulfillment_renewable.set_as_in_process
    @fulfillment_renewable.set_as_sent
    
    TasksHelpers.process_fulfillments_up_today

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    last_fulfillment = Fulfillment.last

    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(last_fulfillment.product_sku)
      assert page.has_content?('sent')
      assert page.has_content?('not_processed')
      assert page.has_content?((I18n.l(last_fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(last_fulfillment.renewable_at, :format => :only_date)))        
      assert page.has_content?((I18n.l(@fulfillment_renewable.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(@fulfillment_renewable.renewable_at, :format => :only_date)))
    end
    last_fulfillment.reload
    @fulfillment_renewable.reload
    assert_equal((I18n.l last_fulfillment.assigned_at, :format => :only_date), (I18n.l Time.zone.now, :format => :only_date))
    assert_equal((I18n.l last_fulfillment.renewable_at, :format => :only_date), (I18n.l last_fulfillment.assigned_at + 1.year, :format => :only_date))
    assert_equal(last_fulfillment.status, 'not_processed')
    assert_equal(last_fulfillment.recurrent, true )
    assert_equal(last_fulfillment.renewed, false )
    assert_equal(@fulfillment_renewable.renewed, true )
  end


  test "Fulfillments to be renewable with status out_of_stock" do
    setup_user
    @product_recurrent = FactoryGirl.create(:product_without_stock_and_recurrent, :club_id => @club.id)
    @fulfillment_renewable = FactoryGirl.create(:fulfillment, :product_sku => @product_recurrent.sku, :user_id => @saved_user.id, :recurrent => true, :club_id => @club.id)
    @fulfillment_renewable.update_attribute(:renewable_at, Time.zone.now)
    
    TasksHelpers.process_fulfillments_up_today

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    last_fulfillment = Fulfillment.last

    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
        assert page.has_content?(last_fulfillment.product_sku)
        assert page.has_content?('out_of_stock')
        assert page.has_content?((I18n.l(last_fulfillment.assigned_at, :format => :only_date)))
        assert page.has_content?((I18n.l(last_fulfillment.renewable_at, :format => :only_date)))        
        assert page.has_content?((I18n.l(@fulfillment_renewable.assigned_at, :format => :only_date)))
        assert page.has_content?((I18n.l(@fulfillment_renewable.renewable_at, :format => :only_date)))
    end
    last_fulfillment.reload
    @fulfillment_renewable.reload
    assert_equal((I18n.l last_fulfillment.assigned_at, :format => :only_date), (I18n.l Time.zone.now, :format => :only_date))
    assert_equal((I18n.l last_fulfillment.renewable_at, :format => :only_date), (I18n.l last_fulfillment.assigned_at + 1.year, :format => :only_date))
    assert_equal(last_fulfillment.status, 'out_of_stock')
    assert_equal(last_fulfillment.recurrent, true )
    assert_equal(last_fulfillment.renewed, false )
    assert_equal(@fulfillment_renewable.renewed, true )
  end

  test "add a new club" do
    admin_agent = FactoryGirl.create(:confirmed_admin_agent)

    @partner = FactoryGirl.create(:partner)
    unsaved_club = FactoryGirl.build(:simple_club_with_gateway)    
    sign_in_as(admin_agent)

    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[api_username]', :with => unsaved_club.api_username
    fill_in 'club[api_password]', :with => unsaved_club.api_password
    attach_file('club[logo]', "#{Rails.root}/test/integration/test_img.png")
    check('club[requires_external_id]')
    select('application', :from => 'club[theme]')
    assert_difference('Product.count',1) do
      click_link_or_button 'Create Club'
    end
    assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    visit clubs_path(@partner.prefix)

    within("#clubs_table")do
      click_link_or_button 'Products'
    end

    product_one = Product.first
    product_two = Product.last
    within("#products_table")do
      assert page.has_content?(product_one.sku)
      assert page.has_content?('true')
      assert page.has_content?(product_one.stock.to_s)
      assert page.has_content?(product_one.weight.to_s)
      assert page.has_content?(product_two.sku)
      assert page.has_content?('true')
      assert page.has_content?(product_two.stock.to_s)
      assert page.has_content?(product_two.weight.to_s)
    end
      assert_equal(product_one.recurrent, true)
      assert_equal(product_two.recurrent, true)
  end

  test "see product type at Fulfillment report page" do
    setup_user
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      assert page.has_content?('Kit-card')
      assert page.has_content?('Sloops')
    end
  end

  test "kit fulfillment without stock." do
    setup_user(false)
    @product.update_attribute(:stock,0)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")

    fulfillment = Fulfillment.find_by_product_sku(@product.sku)

    within("#fulfillments_table")do
      check('all_times')
      select('out_of_stock', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?("#{fulfillment.user.id}")
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?('out_of_stock')
    end
  end

  test "Create a report fulfillment selecting KIT at product type." do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillments = Fulfillment.joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND fulfillment.club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id])
    fulfillment = fulfillments.first
    
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")

    fulfillment = Fulfillment.find_by_product_sku(@product.sku)

    within("#fulfillments_table")do
      select('not_processed', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end

    csv_string = Fulfillment.generateCSV(fulfillments, true, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,ZIP,Product,Charter Member Status\n#{@saved_user.id},#{@saved_user.first_name},#{@saved_user.last_name},#{(I18n.l @saved_user.user_since_date, :format => :only_date_short)},#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)},#{@saved_user.address},#{@saved_user.city},#{@saved_user.zip},KIT,\n")

    within("#fulfillments_table")do
      check('all_times')
      select('in_process', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end

    click_link_or_button 'Report'

    within("#report_results")do
        assert page.has_content?("#{fulfillment.user.id}")
        assert page.has_content?(fulfillment.user.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('in_process') 
        assert page.has_selector?('#mark_as_sent')
      click_link_or_button('Mark as sent')
    assert page.has_content?("Fulfillment #{product.sku} was set as sent.")
    end
    fulfillment.reload
    assert_equal(fulfillment.status,'sent')
  end 

  test "change status of fulfillment CARD from not_processed to sent" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    fulfillments = Fulfillment.joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id])
    fulfillment = fulfillments.first
    
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")

    fulfillment = Fulfillment.find_by_product_sku(@product.sku)

    within("#fulfillments_table")do
      select('not_processed', :from => 'status')
      select('Card',:from => 'product_type')
    end

    csv_string = Fulfillment.generateCSV(fulfillments, true, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,ZIP,Product,Charter Member Status\n#{@saved_user.id},#{@saved_user.first_name},#{@saved_user.last_name},#{(I18n.l @saved_user.user_since_date, :format => :only_date_short)},#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)},#{@saved_user.address},#{@saved_user.city},#{@saved_user.zip},CARD,\n")

    within("#fulfillments_table")do
      check('all_times')
      select('in_process', :from => 'status')
      select('Card',:from => 'product_type')
    end

    click_link_or_button 'Report'
    within("#report_results")do
        assert page.has_content?("#{fulfillment.user.id}")
        assert page.has_content?(fulfillment.user.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('in_process') 
        assert page.has_selector?('#mark_as_sent')
      click_link_or_button('Mark as sent')
      assert page.has_content?("Fulfillment #{@product.sku} was set as sent.")
    end
    fulfillment.reload
    assert_equal(fulfillment.status,'sent')
  end 

  test "do not show fulfillment KIT with status = sent actions when user is lapsed." do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_user_throught_sloop(enrollment_info)
    fulfillment = Fulfillment.last
    fulfillment.set_as_in_process
    fulfillment.set_as_sent

    @saved_user = User.find_by_email(@user.email)
    @saved_user.set_as_canceled

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
  
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?('sent')
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?((I18n.t('activerecord.attributes.user.is_lapsed')))
      assert page.has_no_selector?('#resend')
    end
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('sent', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?('sent')
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?((I18n.t('activerecord.attributes.user.is_lapsed')))
      assert page.has_no_selector?('#resend')
    end
  end

  test "do not show fulfillment CARD with status = sent actions when user is lapsed." do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_user_throught_sloop(enrollment_info)
    fulfillment = Fulfillment.last
    fulfillment.set_as_in_process
    fulfillment.set_as_sent

    @saved_user = User.find_by_email(@user.email)
    @saved_user.set_as_canceled

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
  
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?('sent')
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?((I18n.t('activerecord.attributes.user.is_lapsed')))
      assert page.has_no_selector?('#resend')
    end
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('sent', :from => 'status')
      select('Card',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?('sent')
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_content?((I18n.t('activerecord.attributes.user.is_lapsed')))
      assert page.has_no_selector?('#resend')
    end
  end

  test "not_processed and in_process fulfillments should be updated to bad_address when set_wrong_address" do
    setup_user(false)
    product_other = FactoryGirl.create(:product, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product_other.sku},CARD,KIT")

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    fulfillment_card = Fulfillment.find_by_product_sku(@product.sku)
    fulfillment_other = Fulfillment.find_by_product_sku(product_other.sku)
    fulfillment_other.set_as_in_process
    @saved_user.set_wrong_address(@admin_agent, 'reason')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('bad_address', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?('bad_address')
      assert page.has_content?(product_card.sku)
      assert page.has_content?((I18n.t('activerecord.attributes.user.bad_address')))
    end
    within("#fulfillments_table")do
      check('all_times')
      select('bad_address', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?('bad_address')
      assert page.has_content?(product_other.sku)
      assert page.has_content?((I18n.t('activerecord.attributes.user.bad_address')))
      assert page.has_no_selector?('#resend')
    end
  end

  test "kit and card renewed fulfillments should not set as bad_address" do
    setup_user(false)
    product_other = FactoryGirl.create(:product, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product_other.sku},CARD,KIT")

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    fulfillment_card = Fulfillment.find_by_product_sku(@product.sku)
    fulfillment_card.update_attribute(:renewed, true)

    @saved_user.set_wrong_address(@admin_agent,'reason')

    visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('not_processed', :from => 'status')
      choose('radio_product_type_KIT-CARD')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?('not_processed')
      assert page.has_content?(product_card.sku)
      assert page.has_content?((I18n.t('activerecord.attributes.fulfillment.renewed')))
    end
 end

  test "fulfillment record at not_processed status - recurrent = false" do
    setup_user(false)
    product = FactoryGirl.create(:product_without_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)
      assert_equal((I18n.l(fulfillment.assigned_at, :format => :only_date)),(I18n.l(fulfillment.user.join_date, :format => :only_date)))
      assert_equal(fulfillment.renewable_at,nil)
      assert_equal(fulfillment.status,'not_processed')
      assert_equal(fulfillment.recurrent,false)
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('not_processed', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?('not_processed')
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
    end
    fulfillments = Fulfillment.joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id]).type_others

    csv_string = Fulfillment.generateCSV(fulfillments, true, true) 
    assert_equal(csv_string, "PackageId,Costcenter,Companyname,Address,City,State,Zip,Endorsement,Packagetype,Divconf,Bill Transportation,Weight,UPS Service\n#{fulfillment.tracking_code},#{fulfillment.product_sku},#{@saved_user.full_name},#{@saved_user.address},#{@saved_user.city},#{@saved_user.state},#{@saved_user.zip},Return Service Requested,Irregulars,Y,Shipper,,MID\n")
  
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
  
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?('in_process')
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_selector?("#mark_as_sent")
    end
  end

  test "fulfillment record at not_processed status - recurrent = true" do
    setup_user(false)
    product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    assert_equal((I18n.l(fulfillment.assigned_at, :format => :only_date)),(I18n.l(fulfillment.user.join_date, :format => :only_date)))
    assert_equal((I18n.l(fulfillment.renewable_at, :format => :only_date)),(I18n.l(fulfillment.assigned_at + 1.year, :format => :only_date)))
    assert_equal(fulfillment.status,'not_processed')
    assert_equal(fulfillment.recurrent,true)
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){click_link_or_button("Fulfillments")}
    page.has_content?("Fulfillments")
    within("#fulfillments_table")do
      check('all_times')
      select('not_processed', :from => 'status')
      choose('radio_product_type_SLOOPS')
    end
    click_link_or_button('Report')
    within("#report_results")do
      assert page.has_content?('not_processed')
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?(fulfillment.tracking_code)
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
    end
    fulfillments = Fulfillment.joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id]).type_others

    csv_string = Fulfillment.generateCSV(fulfillments, true, true) 
    assert_equal(csv_string, "PackageId,Costcenter,Companyname,Address,City,State,Zip,Endorsement,Packagetype,Divconf,Bill Transportation,Weight,UPS Service\n#{fulfillment.tracking_code},#{fulfillment.product_sku},#{@saved_user.full_name},#{@saved_user.address},#{@saved_user.city},#{@saved_user.state},#{@saved_user.zip},Return Service Requested,Irregulars,Y,Shipper,,MID\n")
  
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
  
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('in_process')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
        assert page.has_selector?("#mark_as_sent")
    end
  end

  test "Generate CSV with fulfillment at in_process status." do
    setup_user(false)
    product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    
    fulfillment.set_as_in_process

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?('in_process')
      assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :only_date)))
      assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :only_date)))
      assert page.has_selector?("#mark_as_sent")
    end

    fulfillments = Fulfillment.joins(:user).where('fulfillments.status = ? and club_id = ?', 'in_process', @club.id).type_others
    csv_string = Fulfillment.generateCSV(fulfillments, true, true) 
    assert_equal(csv_string, "PackageId,Costcenter,Companyname,Address,City,State,Zip,Endorsement,Packagetype,Divconf,Bill Transportation,Weight,UPS Service\n#{fulfillment.tracking_code},#{fulfillment.product_sku},#{@saved_user.full_name},#{@saved_user.address},#{@saved_user.city},#{@saved_user.state},#{@saved_user.zip},Return Service Requested,Irregulars,Y,Shipper,,MID\n")
  end

  
  test "Create a report fulfillment selecting CARD at product type - Chapter user status" do
    setup_user(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{@product.sku}")

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    fulfillment = Fulfillment.find_by_product_sku(@product.sku)
    fulfillment.set_as_in_process

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    click_link_or_button 'Edit'
    select('VIP', :from => 'user_member_group_type_id')
    alert_ok_js
    click_link_or_button 'Update User'

    visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#fulfillments_table")do
      check('all_times')
      select('in_process', :from => 'status')
      choose 'radio_product_type_KIT-CARD'
    end

    click_link_or_button 'Report'
    fulfillments = Fulfillment.joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'in_process', Date.today, Date.today, @club.id]).type_card
    csv_string = Fulfillment.generateCSV(fulfillments, true, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,STATE,ZIP,Product,Charter Member Status\n#{@saved_user.id},#{@saved_user.first_name},#{@saved_user.last_name},#{(I18n.l @saved_user.user_since_date, :format => :only_date_short)},#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)},#{@saved_user.address},#{@saved_user.city},#{@saved_user.state},#{@saved_user.zip},#{product.sku},C\n")    
  end

    
  test "Pass product to Not Processed status with stock" do
    setup_user(false)
    product = FactoryGirl.create(:product, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    visit clubs_path(@partner.prefix)

    within("#clubs_table")do
      click_link_or_button 'Products'
  end

  within("#products_table")do
    assert page.has_content?((product.stock-1).to_s)
  end
    search_fulfillments(false, nil, nil, nil, 'sloops')
    within("#report_results"){
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?(@saved_user.full_name)
    }
  end

  test "Pass product to Not Processed status without stock" do
    setup_user(false)
    @product.update_attribute :stock , 0
    @product.update_attribute :allow_backorder , false
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{@product.sku}")

    assert_difference("User.count",0)do
      create_user_throught_sloop(enrollment_info)
    end
    assert_equal @response.body, '{"message":"You are trying to move a member to a fulfillment queue for a product that has no stock. Add stock or set to allow backorders","code":"'+Settings.error_codes.product_out_of_stock+'"}'
  end

  #Search fulfillment at "Not Processed" status from Initial Date to End Date
  test "Search fulfillment at Not Processed status by 'all times' checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    search_fulfillments(true)
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end

    search_fulfillments
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end
  end

  #Search fulfillment at "In Process" status from Initial Date to End Date
  test "Search fulfillment at 'In Process' status by 'all times' checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(true,nil,nil,'in_process')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end

    search_fulfillments(false,nil,nil,'in_process')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end
  end 

  #Search fulfillment at "On Hold" status from Initial Date to End Date
  test "Search fulfillment at 'On Hold' status by 'all times' checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    @saved_user.fulfillments.each &:set_as_on_hold

    search_fulfillments(true,nil,nil,'on_hold')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end

    search_fulfillments(false,nil,nil,'on_hold')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end
  end 

  #Search fulfillment at "Sent" status from Initial Date to End Date
  test "Search fulfillment at 'Sent' status by 'all times' checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    @saved_user.fulfillments.each &:set_as_sent

    search_fulfillments(true,nil,nil,'sent')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end

    search_fulfillments(false,nil,nil,'sent')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end
  end 

  # Search fulfillment at "Out of Stock" status from Initial Date to End Date
  test "Search fulfillment at 'Out of Stock' status by 'all times' checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    @saved_user.fulfillments.each &:set_as_out_of_stock

    search_fulfillments(true,nil,nil,'out_of_stock')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end

    search_fulfillments(false,nil,nil,'out_of_stock')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end
  end

  # Search fulfillment at "Returned" status from Initial Date to End Date
  test "Search fulfillment at 'Returned' status by 'all times' checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(true,nil,nil,'returned')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end

    search_fulfillments(false,nil,nil,'returned')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end
  end

  # Search fulfillment at "Bad address" status from Initial Date to End Date
  test "Search fulfillment at 'Bad address' status by 'all times' checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(true,nil,nil,'bad_address')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end

    search_fulfillments(false,nil,nil,'bad_address')
    within("#report_results")do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
    end
  end

  test "Update the status of all the fulfillments - In Process selecting the All results checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(false,nil,nil,'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(false,nil,nil,'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process
    
    search_fulfillments(false,nil,nil,'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process
    
    search_fulfillments(false,nil,nil,'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process
    
    search_fulfillments(false,nil,nil,'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process
    
    search_fulfillments(false,nil,nil,'in_process')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
  end

  test "Update the status of all the fulfillments - Not processed selecting the All results checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    search_fulfillments(false,nil,nil,'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed

    search_fulfillments(false,nil,nil,'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed
    
    search_fulfillments(false,nil,nil,'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed
    
    search_fulfillments(false,nil,nil,'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed
    
    search_fulfillments(false,nil,nil,'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed
    
    search_fulfillments(false,nil,nil,'not_processed')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
  end

  test "Update the status of all the fulfillments - On Hold selecting the All results checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_on_hold

    search_fulfillments(false,nil,nil,'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold

    search_fulfillments(false,nil,nil,'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold
    
    search_fulfillments(false,nil,nil,'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold
    
    search_fulfillments(false,nil,nil,'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold
    
    search_fulfillments(false,nil,nil,'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold
    
    search_fulfillments(false,nil,nil,'on_hold')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
  end

test "Update the status of all the fulfillments - Sent selecting the All results checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_sent

    search_fulfillments(false,nil,nil,'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent

    search_fulfillments(false,nil,nil,'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent
    
    search_fulfillments(false,nil,nil,'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent
    
    search_fulfillments(false,nil,nil,'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent
    
    search_fulfillments(false,nil,nil,'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent
    
    search_fulfillments(false,nil,nil,'sent')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
  end

  test "Update the status of all the fulfillments - Out of Stock selecting the All results checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_out_of_stock

    search_fulfillments(false,nil,nil,'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock

    search_fulfillments(false,nil,nil,'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock
    
    search_fulfillments(false,nil,nil,'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock
    
    search_fulfillments(false,nil,nil,'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock
    
    search_fulfillments(false,nil,nil,'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock
    
    search_fulfillments(false,nil,nil,'out_of_stock')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
  end

  test "Update the status of all the fulfillments - Returned selecting the All results checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(false,nil,nil,'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(false,nil,nil,'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned
    
    search_fulfillments(false,nil,nil,'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned
    
    search_fulfillments(false,nil,nil,'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned
    
    search_fulfillments(false,nil,nil,'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned
    
    search_fulfillments(false,nil,nil,'returned')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
  end

  test "Update the status of all the fulfillments - Bad address selecting the All results checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(false,nil,nil,'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(false,nil,nil,'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address
    
    search_fulfillments(false,nil,nil,'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address
    
    search_fulfillments(false,nil,nil,'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address
    
    search_fulfillments(false,nil,nil,'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address
    
    search_fulfillments(false,nil,nil,'bad_address')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
  end

  test "Update the status of the fulfillments - Not processed using individual checkboxes" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

test "Update the status of all the fulfillments - In process using individual checkboxes" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_in_process

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test "Update the status of all the fulfillments - On hold using individual checkboxes" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_on_hold

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test "Update the status of all the fulfillments - Sent using individual checkboxes" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_sent

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test "Update the status of all the fulfillments - Out of Stock using individual checkboxes" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_out_of_stock

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test "Update the status of all the fulfillments - Returned using individual checkboxes" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_returned

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test "Update the status of all the fulfillments - Bad address using individual checkboxes" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_bad_address

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'bad_address')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')
  end

  test "Error message if changing from one status to same status" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'not_processed')

    alert_ok_js
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', false, 'KIT-CARD', false)
    within("#report_results"){ assert page.has_content?("Nothing to change on KIT-CARD fulfillment.") }
  end
  
  test "Error message if changing from one status to 'blank' status" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'not_processed')

    alert_ok_js
    
    within("#report_results")do
      check "fulfillment_selected[#{fulfillments[0].id}]"
      click_link_or_button 'Update status'
    end

    within("#report_results"){ assert page.has_content?("New status is blank. Please, select a new status to be applied.") }
  end

  test "Search fulfillments with Initial Date > End Date" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false,nil,nil,'not_processed')

    alert_ok_js
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', false, 'KIT-CARD', false)
    within("#report_results"){ assert page.has_content?("Nothing to change on KIT-CARD fulfillment.") }
  end

  # Create a fulfillment file with all times and with kit-card product
  # See "Create XLS file" button - All time checkbox
  test "Create file at 'all time' checkbox" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first
    fulfillments << @saved_user.fulfillments.last

    generate_fulfillment_files(true, fulfillments)
    
    fulfillments = @saved_user.fulfillments
  end

  test "Create file at Date range" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first
    fulfillments << @saved_user.fulfillments.last

    generate_fulfillment_files(false, fulfillments)
  end

  test "Create a fulfillment file with all times and with sloop product" do
    setup_user(false)
    active_merchant_stubs
    product = FactoryGirl.create(:product, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")
    create_user_throught_sloop(enrollment_info)
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first
    
    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    generate_fulfillment_files(true, fulfillments,nil, nil, nil, 'sloops')
  end

  test "Create a fulfillment file with initial-end dates and with sloop product" do
    setup_user(false)
    active_merchant_stubs
    product = FactoryGirl.create(:product, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first

    generate_fulfillment_files(false, fulfillments, nil, nil, nil, 'sloops')
  end

  test "Create a fulfillment file with initial-end dates and with sloop product 2" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    all_fulfillments = @saved_user.fulfillments
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first
    generate_fulfillment_files(false, fulfillments, nil, nil, 'not_processed', nil, false)

    fulfillments = []
    fulfillments << @saved_user.fulfillments[1]
    fulfillments << @saved_user.fulfillments[2]
    generate_fulfillment_files(false, fulfillments, nil, nil, 'not_processed', nil, false)

    fulfillments = []
    fulfillments << @saved_user.fulfillments[3]
    fulfillments << @saved_user.fulfillments[4]
    generate_fulfillment_files(false, fulfillments, nil, nil, 'not_processed', nil, false)

    visit list_fulfillment_files_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    

    fulfillment_files = FulfillmentFile.all
    assert_equal fulfillment_files.count, 3

    within("#fulfillment_files_table") do
      fulfillment_files.each do |fulfillment_file|
        assert page.has_content?(fulfillment_file.id.to_s)
        assert page.has_content?(fulfillment_file.status)
        assert page.has_content?(fulfillment_file.product)
        assert page.has_content?(fulfillment_file.dates)
        assert page.has_content?(fulfillment_file.fulfillments_processed)
      end
    end
  end

  # Mark as sent - fulfillment file
  test "Check fulfillment file at sent status" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    generate_fulfillment_files(false, @saved_user.fulfillments, nil, nil, 'not_processed', nil, false)
    
    visit list_fulfillment_files_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

    within("#fulfillment_files_table")do
      confirm_ok_js
      click_link_or_button 'Mark as sent'
    end
    assert page.has_content?("Fulfillment file marked as sent successfully")

    within("#fulfillment_files_table")do
      assert page.has_content?("sent")
      assert page.has_no_selector?("#mark_as_sent")
    end

    file = FulfillmentFile.last
    assert_equal file.status, "sent"
  end  

  test "Agents can not change fulfillment status from User Profile" do
    setup_user(false)
    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)
    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs'){ click_on 'Fulfillments'}
    within('#fulfillments'){ assert page.has_no_selector?("#mark_as_sent")}
    within('#fulfillments'){ assert page.has_no_selector?("#update_fulfillment_status")}
  end

  test "Mark an user as 'wrong address' - Admin Role - not_processed status" do
    setup_user(true)
    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}

    set_as_undeliverable_user(@saved_user,'reason')

    within("#table_demographic_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_user.reload

    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end 

  test "Mark an user as 'wrong address' - In Process status" do
    setup_user(true)
    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_in_process

    set_as_undeliverable_user(@saved_user,'reason')

    within("#table_demographic_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_user.reload

    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end

  test "Mark an user as 'wrong address' - Out of stock status" do
    setup_user(true)
    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_out_of_stock

    set_as_undeliverable_user(@saved_user,'reason')

    within("#table_demographic_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_user.reload

    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end

  test "Mark an user as 'wrong address' - Returned status" do
    setup_user(true)
    3.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)}
    @saved_user.fulfillments.each &:set_as_returned

    set_as_undeliverable_user(@saved_user,'reason')

    within("#table_demographic_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_user.reload

    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end  

  # fulfillment_managment role - Fulfillment File page
  test "Fulfillments file page should filter the results by Club" do
    setup_user(false)
    @club2 = FactoryGirl.create(:simple_club_with_gateway)

    active_merchant_stubs
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_throught_sloop(enrollment_info)

    FactoryGirl.create(:fulfillment_file, :agent_id => @admin_agent.id, :club_id => @club.id, :created_at => Time.zone.now-2.days )
    FactoryGirl.create(:fulfillment_file, :agent_id => @admin_agent.id, :club_id => @club.id, :created_at => Time.zone.now-1.days )
    FactoryGirl.create(:fulfillment_file, :agent_id => @admin_agent.id, :club_id => @club2.id, :created_at => Time.zone.now+1.days )
    FactoryGirl.create(:fulfillment_file, :agent_id => @admin_agent.id, :club_id => @club2.id, :created_at => Time.zone.now+2.days)

    visit list_fulfillment_files_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    fulfillment_file = FulfillmentFile.find_all_by_club_id(@club.id)
    fulfillment_file2 = FulfillmentFile.find_all_by_club_id(@club2.id)
    within("#fulfillment_files_table")do
      assert page.has_content?( I18n.l(fulfillment_file.first.created_at.to_date) )     
      assert page.has_content?( I18n.l(fulfillment_file.last.created_at.to_date) )
      assert page.has_no_content?( I18n.l(fulfillment_file2.first.created_at.to_date) )     
      assert page.has_no_content?( I18n.l(fulfillment_file2.last.created_at.to_date) )
    
      confirm_ok_js
      first(:link, 'Mark as sent').click
    end
    assert page.has_content?("Fulfillment file marked as sent successfully")

    within("#fulfillment_files_table"){ first(:link, 'View').click }

    assert page.has_content?("Fulfillments for file")
  end

  test "Change fulfillment status from Returned to Not Processed when removing undeliverable" do
    setup_user(true)
    stubs_solr_index
    FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)
    @saved_user.fulfillments.each{ |x| x.update_status(nil,"returned","testing") }
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    
    within("#table_demographic_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_user.reload
    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'returned'
    end
    click_link_or_button "Edit" 
    within("#table_demographic_information") do
      fill_in 'user[address]', :with => "new address 123"
    end

    alert_ok_js
    click_link_or_button "Update User"
    @saved_user.reload
    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'not_processed'
    end  
  end

  test "Change fulfillment status from bad_addres to Not Processed when removing undeliverable" do
    setup_user(true)
    stubs_solr_index
    FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD', :club_id => @club.id)
    @saved_user.fulfillments.each{ |x| x.update_status(nil,"bad_address","testing") }
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    
    within("#table_demographic_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_user.reload
    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
    click_link_or_button "Edit" 
    within("#table_demographic_information") do
      fill_in 'user[address]', :with => "new address 123"
    end

    alert_ok_js
    click_link_or_button "Update User"
    @saved_user.reload
    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'not_processed'
    end  
  end
end