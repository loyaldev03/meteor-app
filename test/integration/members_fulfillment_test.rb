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
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)

    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
      @product = FactoryGirl.create(:product, :club_id => @club.id, :sku => 'kit-card')
      @fulfillment = FactoryGirl.create(:fulfillment, :member_id => @saved_member.id, :product_sku => 'kit-card')
		end

    sign_in_as(@admin_agent)
  end

  def create_member_throught_sloop(enrollment_info)
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    create_member_by_sloop(@admin_agent, @member, @credit_card, enrollment_info, @terms_of_membership_with_gateway)
  end

  # ###########################################################
  # # TESTS
  # ###########################################################

  test "cancel member and check if not_processed fulfillments were updated to canceled" do
    setup_member
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('not_processed')
      }
    end

    @saved_member.set_as_canceled!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('canceled')
      }
    end
    @fulfillment.reload
    assert_equal @fulfillment.status, 'canceled'
  end
  
  test "cancel member and check if processing fulfillments were updated to canceled" do
    setup_member
    @fulfillment.set_as_processing

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('processing')
      }
    end

    @saved_member.set_as_canceled!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('canceled')
      }
    end
    @fulfillment.reload
    assert_equal @fulfillment.status, 'canceled'
  end

  test "cancel member and check if out_of_stock fulfillments were updated to canceled" do
    setup_member
    @fulfillment.set_as_out_of_stock
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('out_of_stock')
      }
    end

    @saved_member.set_as_canceled!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('canceled')
      }
    end
    @fulfillment.reload
    assert_equal @fulfillment.status, 'canceled'
  end

  test "cancel member and check if undeliverable fulfillments were updated to canceled" do
    setup_member
    @fulfillment.set_as_processing
    @fulfillment.set_as_undeliverable
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('undeliverable')
      }
    end

    @saved_member.set_as_canceled!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('canceled')
      }
    end
    @fulfillment.reload
    assert_equal @fulfillment.status, 'canceled'
  end 

  test "display 'Mark as sent' and 'Set as wrong number' when fulfillment is processing on memebr's profile." do
    setup_member
    @fulfillment.set_as_processing    

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_selector?('#mark_as_sent')     
      }
    end

    click_link_or_button('mark_as_sent')

    within("#fulfillments")do
      wait_until{
        assert page.has_content?("Fulfillment #{@fulfillment.product_sku} was set as sent.")    
      }
    end
    @fulfillment.reload
    assert_equal @fulfillment.status,'sent'
  end

  test "display 'resend' when fulfillment is out_of_stock on memebr's profile." do
    setup_member
    @fulfillment.set_as_out_of_stock    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_selector?('#resend')     
      }
    end

    click_link_or_button('Resend')

    within("#fulfillments")do
      wait_until{
        assert page.has_content?("Fulfillment #{@fulfillment.product_sku} was marked to be delivered next time.")    
      }
    end
    @fulfillment.reload
    assert_equal @fulfillment.status,'not_processed'
  end

  test "display default initial and end dates on fulfillments index" do
    setup_member
    visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

    within("#fulfillments_table") do
      wait_until{
        assert find_field('initial_date_').value == "#{Date.today-1.week}"
        assert find_field('end_date_').value == "#{Date.today}"
      }
    end
  end

  test "enroll a member with product not available but it on the list at CS and recurrent false" do
    setup_member(false)
    @product = FactoryGirl.create(:product_without_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    assert_difference('Product.find(@product.id).stock',-1) do
      create_member_throught_sloop(enrollment_info)
    end
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, @product.sku)
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, nil)
    assert_equal(fulfillment.status, 'not_processed')
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?(@product.sku)
        assert page.has_content?('not_processed')  
        assert page.has_no_selector?('Resend')
        assert page.has_no_selector?('Mark as sent')
        assert page.has_no_selector?('Set as wrong address')
      }
    end
  end

  test "enroll a member with product not available but it on the list at CS and recurrent true" do
    setup_member(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    assert_difference('Product.find(@product.id).stock',-1) do
      create_member_throught_sloop(enrollment_info)
    end
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.product_sku, @product.sku)
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, fulfillment.assigned_at + 1.year)
    assert_equal(fulfillment.status, 'not_processed')
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?(I18n.l fulfillment.renewable_at, :format => :long)
        assert page.has_content?(@product.sku)
        assert page.has_content?('not_processed') 
        assert page.has_no_selector?('Resend')
        assert page.has_no_selector?('Mark as sent')
        assert page.has_no_selector?('Set as wrong address')
      }
    end
  end

  test "enroll a member with product out of stock and recurrent" do
    setup_member(false)
    @product = FactoryGirl.create(:product_without_stock_and_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, @product.sku)
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, fulfillment.assigned_at + 1.year)
    assert_equal(fulfillment.status, 'out_of_stock')
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?(I18n.l fulfillment.renewable_at, :format => :long)
        assert page.has_content?(@product.sku)
        assert page.has_content?('out_of_stock')  
        assert page.has_no_selector?('Resend')
        assert page.has_no_selector?('Mark as sent')
        assert page.has_no_selector?('Set as wrong address')
      }
    end
  end

  test "enroll a member with product out of stock and not recurrent" do
    setup_member(false)
    @product = FactoryGirl.create(:product_without_stock_and_not_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, @product.sku)
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, nil)
    assert_equal(fulfillment.status, 'out_of_stock')
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?(@product.sku)
        assert page.has_content?('out_of_stock')  
        assert page.has_no_selector?('Resend')
        assert page.has_no_selector?('Mark as sent')
        assert page.has_no_selector?('Set as wrong address')
      }
    end
  end

  test "enroll a member with product not in the list" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'product not in the list')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, 'product not in the list')
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, nil)
    assert_equal(fulfillment.status, 'out_of_stock')
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?('product not in the list')
        assert page.has_content?('out_of_stock')  
        assert page.has_no_selector?('Resend')
        assert page.has_no_selector?('Mark as sent')
        assert page.has_no_selector?('Set as wrong address')
      }
    end
  end

  test "enroll a member with blank product_sku" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => '')
    assert_difference('Fulfillment.count',0){
      create_member_throught_sloop(enrollment_info)
    }
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?('No fulfillments were found.')
      }
    end
  end

test "Enroll a member with recurrent product and it on the list" do
    setup_member(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)
    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    within("#fulfillments_table")do
      check('_all_times')
      select('not_processed', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')

    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_no_selector?('#resend') 
      }
    end
    stock = @product.stock
    @product.reload
    wait_until{ assert_equal(@product.stock,stock-1) }
  end

  test "dislpay default data on fulfillments index" do
    setup_member(false)

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    within("#fulfillments_table")do
      wait_until{
        assert find_field('initial_date_').value == "#{Date.today-1.week}"
        assert find_field('end_date_').value == "#{Date.today}"
        assert page.find_field('status').value == 'not_processed'
        assert page.find_field('_all_times')   
        assert page.find_field('product_type')
      }
    end
  end

  test "fulfillment record at processing + check stock" do
    setup_member(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)
    initial_stock = @product.stock
    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, @product.sku)
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, @saved_member.join_date + 1.year)
    assert_equal(fulfillment.recurrent, true)
    assert_equal(fulfillment.status, 'not_processed')

    fulfillment.set_as_processing

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    within("#fulfillments_table")do
      wait_until{
        assert page.find_field('initial_date_')
        assert page.find_field('end_date_')
        assert page.find_field('status')
        assert page.find_field('_all_times')    
        assert page.find_field('product_type')  
      }
      check('_all_times')
      select('processing', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')

    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('processing') 
      }
    end

    @product.reload

    assert @product.stock == initial_stock-1
  end

  test "resend KIT product with status = sent" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, 'KIT')
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at.year, @saved_member.join_date.year + 1)
    assert_equal(fulfillment.renewable_at.day, @saved_member.join_date.day)
    assert_equal(fulfillment.recurrent, true)
    assert_equal(fulfillment.status, 'not_processed')

    fulfillment.set_as_processing
    fulfillment.set_as_sent

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    within("#fulfillments_table")do
      wait_until{
        assert page.find_field('initial_date_')
        assert page.find_field('end_date_')
        assert page.find_field('status')
        assert page.find_field('_all_times')    
        assert page.find_field('product_type')  
      }
      check('_all_times')
      select('sent', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')

    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('sent') 

        click_link_or_button("Resend")
        assert page.has_content?("Fulfillment KIT was marked to be delivered next time.")
      }
    end
    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, 'KIT')
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, @saved_member.join_date + 1.year)
    assert_equal(fulfillment.recurrent, true)
    assert_equal(fulfillment.status, 'not_processed')
    assert_equal(fulfillment.product.stock,98)
  end

  test "resend fulfillment with status sent and sku OTHERS" do
    setup_member(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => @product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last

    fulfillment.set_as_processing
    fulfillment.set_as_sent

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    within("#fulfillments_table")do
      check('_all_times')
      select('sent', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')

    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_no_selector?('#resend') 
      }
    end
  end
  
  test "resend CARD product with status = sent" do
    setup_member(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'CARD')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, 'CARD')
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at.year, @saved_member.join_date.year + 1)
    assert_equal(fulfillment.renewable_at.day, @saved_member.join_date.day)
    assert_equal(fulfillment.recurrent, true)
    assert_equal(fulfillment.status, 'not_processed')

    fulfillment.set_as_processing
    fulfillment.set_as_sent

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    within("#fulfillments_table")do
      wait_until{
        assert page.find_field('initial_date_')
        assert page.find_field('end_date_')
        assert page.find_field('status')
        assert page.find_field('_all_times')    
        assert page.find_field('product_type')  
      }
      check('_all_times')
      select('sent', :from => 'status')
      select('Card',:from => 'product_type')
    end
    click_link_or_button('Report')

    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('sent') 

        click_link_or_button("Resend")
        assert page.has_content?("Fulfillment CARD was marked to be delivered next time.")
      }
    end

    fulfillment = Fulfillment.last
    assert_equal(fulfillment.member_id, @saved_member.id)
    assert_equal(fulfillment.product_sku, 'CARD')
    assert_equal(fulfillment.assigned_at.year, Time.zone.now.year)
    assert_equal(fulfillment.assigned_at.day, Time.zone.now.day)
    assert_equal(fulfillment.renewable_at, @saved_member.join_date + 1.year)
    assert_equal(fulfillment.recurrent, true)
    assert_equal(fulfillment.status, 'not_processed')
    assert_equal(fulfillment.product.stock,98)
  end

  test "fulfillment record at Processing" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    @saved_member.fulfillments.each do |fulfillment|
      fulfillment.set_as_processing
    end
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    fulfillment = Fulfillment.find_by_product_sku('KIT')
    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('processing') 
        assert page.has_selector?('#mark_as_sent')
        assert page.has_selector?('#set_as_wrong_address')

        click_link_or_button('Set as wrong address')
        wait_until{ page.has_selector?('#reason') }
        fill_in 'reason', :with => 'spam'
        confirm_ok_js
        click_link_or_button('Set wrong address')
        wait_until{ page.has_content?("#{fulfillment.member.full_address} is undeliverable. Reason: spam")}
      }
    end
  end
  
  test "mark sent fulfillment at processing status" do
    setup_member(false)
    product = FactoryGirl.create(:product, :club_id => @club.id, :recurrent => true)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    fulfillment.set_as_processing
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('processing') 
        assert page.has_selector?('#mark_as_sent')
        assert page.has_selector?('#set_as_wrong_address')

        click_link_or_button('Mark as sent')
        wait_until{ assert page.has_content?("Fulfillment #{product.sku} was set as sent.") }
      }
    end
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?(product.sku)
        assert page.has_content?('sent')  
      }
    end
  end

  test "set as wrong address fulfillment at processing status" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT')
    fulfillment.set_as_processing
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('processing') 
        assert page.has_selector?('#mark_as_sent')
        assert page.has_selector?('#set_as_wrong_address')

        click_link_or_button('Set as wrong address')
        wait_until{ page.has_selector?('#reason') }
        fill_in 'reason', :with => 'spam'
        confirm_ok_js
        click_link_or_button('Set wrong address')
        wait_until{ page.has_content?("#{fulfillment.member.full_address} is undeliverable. Reason: spam")}
      }
    end
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?('KIT')
        assert page.has_content?('undeliverable')  
      }
    end
  end

  test "display fulfillment record at out_of_stock status" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT')
    fulfillment.set_as_out_of_stock
    product = fulfillment.product
    product.stock = 0
    product.save

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('out_of_stock', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('out_of_stock') 
        assert page.has_content?('Actual stock: 0.')
      }
    end
  end

  test "add stock and check fulfillment record with out_of_stock status" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT')
    fulfillment.set_as_out_of_stock
    product = fulfillment.product
    product.stock = 0
    product.save

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('out_of_stock', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('out_of_stock') 
        assert page.has_content?('Actual stock: 0.')
      }
    end
    visit products_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#products_table")do
      wait_until{ click_link_or_button('Edit') }
    end
    wait_until{ page.has_content?('Edit Product') }
    fill_in 'product[stock]', :with => '10'
    click_link_or_button('Update Product')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('out_of_stock', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('out_of_stock') 
        assert page.has_content?('Actual stock: 10.')
        assert page.has_selector?("#resend")
      }
    end
  end

  test "resend fulfillment - Product out of stock" do
    setup_member(false)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'KIT')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku('KIT')
    fulfillment.set_as_out_of_stock
    product = fulfillment.product
    product.stock = 0
    product.save

    visit products_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#products_table")do
      wait_until{ click_link_or_button('Edit') }
    end
    wait_until{ page.has_content?('Edit Product') }
    fill_in 'product[stock]', :with => '10'
    click_link_or_button('Update Product')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('out_of_stock', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('out_of_stock') 
        assert page.has_content?('Actual stock: 10.')
        assert page.has_selector?("#resend")
      }
      click_link_or_button('Resend')
      wait_until{ assert page.has_content?('Fulfillment KIT was marked to be delivered next time.') }
    end
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(I18n.l @saved_member.join_date, :format => :long)
        assert page.has_content?('KIT')
        assert page.has_content?('not_processed')  
      }
    end
  end

  test "renewal as out_of_stock and set renewed when product does not have stock" do
    setup_member(false)
    product = FactoryGirl.create(:product, :recurrent => true, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku(product.sku)
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
        assert page.has_content?(product.sku)
        assert page.has_content?('out_of_stock')
        assert page.has_content?('sent')
      }
    end
    fulfillment.reload
    fulfillment_new = Fulfillment.last
    wait_until{
      assert_equal(fulfillment_new.product_sku, fulfillment.product_sku)
      assert_equal((I18n.l fulfillment_new.assigned_at, :format => :long), (I18n.l Time.zone.now, :format => :long))
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

  test "renewed 'sent' fulfillment should not show resend." do
    setup_member(false)
    product = FactoryGirl.create(:product, :recurrent => true, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku )

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    fulfillment.set_as_processing
    fulfillment.set_as_sent

    fulfillment.renew!

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('sent', :from => 'status')
      select('Others',:from => 'product_type')
    end

    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('sent')
        assert page.has_content?('Renewed')
        assert page.has_no_selector?('#resend')
      }
    end
  end

  test "fulfillment status undeliverable" do
    setup_member

    @fulfillment.set_as_processing
    @saved_member.set_wrong_address(@admin_agent, 'admin')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('undeliverable', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')
    @fulfillment.reload
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{@fulfillment.member.visible_id}")
        assert page.has_content?(@fulfillment.member.full_name)
        assert page.has_content?((I18n.l(@fulfillment.assigned_at, :format => :long)))
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?(@fulfillment.tracking_code)
        assert page.has_content?('undeliverable')
      }
    end
  end

  test "Resend fulfillment with status undeliverable - Product with stock" do
    setup_member

    @fulfillment.set_as_processing
    @saved_member.set_wrong_address(@admin_agent, 'admin')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('undeliverable', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')
    @fulfillment.reload
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{@fulfillment.member.visible_id}")
        assert page.has_content?(@fulfillment.member.full_name)
        assert page.has_content?((I18n.l(@fulfillment.assigned_at, :format => :long)))
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?(@fulfillment.tracking_code)
        assert page.has_content?('undeliverable')
        click_link_or_button('This address is undeliverable.')
      }
    end
    click_link_or_button 'Edit'

    within("#table_demographic_information")do
      wait_until{
        check('setter_wrong_address')
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?('not_processed')
      }
    end
  end

  ## FIXME: The update button keep throwing and error.
  # test "resend fulfillment with status undeliverable - Product without stock" do
  #   setup_member(false)
  #   @saved_member = FactoryGirl.create(:active_member, :club_id => @club.id, 
  #                                      :terms_of_membership => @terms_of_membership_with_gateway,
  #                                      :created_by => @admin_agent)

  #   @saved_member.reload
  #   @product = FactoryGirl.create(:product_without_stock_and_recurrent, :club_id => @club.id)
  #   @fulfillment = FactoryGirl.create(:fulfillment, :member_id => @saved_member.id, :product_sku => @product.sku)
    
  #   @fulfillment.set_as_processing
  #   @saved_member.set_wrong_address(@admin_agent, 'admin')

  #   click_link_or_button("My Clubs")
  #   within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
  #   wait_until{page.has_content?("Fulfillments")}
  #   within("#fulfillments_table")do
  #     check('_all_times')
  #     select('undeliverable', :from => 'status')
  #     select('Others',:from => 'product_type')
  #   end
  #   click_link_or_button('Report')
  #   @fulfillment.reload
  #   within("#report_results")do
  #     wait_until{
  #       assert page.has_content?("#{@fulfillment.member.visible_id}")
  #       assert page.has_content?(@fulfillment.member.full_name)
  #       assert page.has_content?((I18n.l(@fulfillment.assigned_at, :format => :long)))
  #       assert page.has_content?(@fulfillment.product_sku)
  #       assert page.has_content?(@fulfillment.tracking_code)
  #       assert page.has_content?('undeliverable')
  #       click_link_or_button('This address is undeliverable.')
  #     }
  #   end
  #   click_link_or_button 'Edit'

  #   within("#table_demographic_information")do
  #     wait_until{
  #       check('setter_wrong_address')
  #     }
  #   end
  #   alert_ok_js
  #   click_link_or_button 'Update Member'
  #   wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  #   within(".nav-tabs") do
  #     click_on("Fulfillments")
  #   end
  #   within("#fulfillments")do
  #     wait_until{
  #       assert page.has_content?(@fulfillment.product_sku)
  #       assert page.has_content?('out_of_stock')
  #     }
  #   end
  # end

  test "fulfillment record from not_processed to cancel status" do
    setup_member

    @saved_member.set_as_canceled
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within("#table_membership_information")do
      wait_until{
        assert page.has_content?('lapsed')
      }
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?('canceled')
      }
    end
  end

  test "fulfillment record from processing to cancel status" do
    setup_member
    @fulfillment.set_as_processing

    @saved_member.set_as_canceled
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within("#table_membership_information")do
      wait_until{
        assert page.has_content?('lapsed')
      }
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?('canceled')
      }
    end
  end

  test "fulfillment record from out_of_stock to cancel status" do
    setup_member
    @fulfillment.set_as_out_of_stock

    @saved_member.set_as_canceled
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within("#table_membership_information")do
      wait_until{
        assert page.has_content?('lapsed')
      }
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?('canceled')
      }
    end
  end

  test "fulfillment record from undeliverable to cancel status" do
    setup_member
    @fulfillment.set_as_processing
    @saved_member.set_wrong_address(@admin_agent, 'admin')
    @fulfillment.reload
    wait_until{ assert_equal(@fulfillment.status, 'undeliverable') }
    @saved_member.set_as_canceled
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within("#table_membership_information")do
      wait_until{
        assert page.has_content?('lapsed')
      }
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?('canceled')
      }
    end
  end

  test "fulfillment record at sent status when member is canceled" do
    setup_member

    @fulfillment.set_as_processing
    @fulfillment.set_as_sent
    wait_until{ assert_equal(@fulfillment.status, 'sent') }
    @saved_member.set_as_canceled
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within("#table_membership_information")do
      wait_until{
        assert page.has_content?('lapsed')
      }
    end
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?('sent')
      }
    end
  end

  test "Fulfillments to be renewable with status canceled" do
    setup_member
    @product_recurrent = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    @fulfillment_renewable = FactoryGirl.create(:fulfillment, :product_sku => @product_recurrent.sku, :member_id => @saved_member.id)

    @fulfillment_renewable.set_as_canceled
    @fulfillment_renewable.reload
    @fulfillment.renew!
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(@fulfillment_renewable.product_sku)
        assert page.has_content?('canceled')
      }
    end
    @fulfillment_renewable.reload
    wait_until{ assert_equal(@fulfillment_renewable.renewed,false) }
  end

  test "resend fulfillment" do
    setup_member
    @fulfillment.set_as_out_of_stock

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(@fulfillment.product_sku)
        assert page.has_content?('out_of_stock')
        click_link_or_button 'Resend'
        wait_until{ page.has_content?("Fulfillment #{@fulfillment.product_sku} was marked to be delivered next time.") }
        wait_until{ assert_equal(Operation.last.description, "Fulfillment #{@fulfillment.product_sku} was marked to be delivered next time.") }
      }
    end
  end

  test "fulfillments to be renewable with status sent" do
    setup_member
    @product_recurrent = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    @fulfillment_renewable = FactoryGirl.create(:fulfillment, :product_sku => @product_recurrent.sku, :member_id => @saved_member.id, :recurrent => true)
    @fulfillment_renewable.update_attribute(:renewable_at, Date.today)
    @fulfillment_renewable.set_as_processing
    @fulfillment_renewable.set_as_sent
    @fulfillment_renewable.renew!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    last_fulfillment = Fulfillment.last

    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(last_fulfillment.product_sku)
        assert page.has_content?('sent')
        assert page.has_content?('not_processed')
        assert page.has_content?((I18n.l(last_fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(last_fulfillment.renewable_at, :format => :long)))        
        assert page.has_content?((I18n.l(@fulfillment_renewable.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(@fulfillment_renewable.renewable_at, :format => :long)))
      }
    end
    last_fulfillment.reload

    wait_until{ assert_equal((I18n.l last_fulfillment.assigned_at, :format => :long), (I18n.l Date.today, :format => :long)) }
    wait_until{ assert_equal((I18n.l last_fulfillment.renewable_at, :format => :long), (I18n.l last_fulfillment.assigned_at + 1.year, :format => :long)) }
    wait_until{ assert_equal(last_fulfillment.status, 'not_processed') }
    wait_until{ assert_equal(last_fulfillment.recurrent, true ) }
    wait_until{ assert_equal(last_fulfillment.renewed, false ) }
    wait_until{ assert_equal(@fulfillment_renewable.renewed, true ) }
  end

  test "add a new club" do
    setup_member
    @partner = FactoryGirl.create(:partner)
    unsaved_club = FactoryGirl.build(:simple_club_with_gateway)    

    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[api_username]', :with => unsaved_club.api_username
    fill_in 'club[api_password]', :with => unsaved_club.api_password
    attach_file('club[logo]', "#{Rails.root}/test/integration/test_img.png")
    check('club[requires_external_id]')
    select('application', :from => 'club[theme]')
    assert_difference('Product.count',2) do
      click_link_or_button 'Create Club'
    end
    assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    visit clubs_path(@partner.prefix)

    within("#clubs_table")do
      wait_until{ click_link_or_button 'Products' }
    end

    product_one = Product.first
    product_two = Product.last
    within("#products_table")do
      wait_until{
        assert page.has_content?(product_one.sku)
        assert page.has_content?('true')
        assert page.has_content?(product_one.stock.to_s)
        assert page.has_content?(product_one.weight.to_s)
        assert page.has_content?(product_two.sku)
        assert page.has_content?('true')
        assert page.has_content?(product_two.stock.to_s)
        assert page.has_content?(product_two.weight.to_s)
      }
    end
    wait_until{
      assert_equal(product_one.recurrent, true)
      assert_equal(product_two.recurrent, true)
    }
  end

  test "see product type at Fulfillment report page" do
    setup_member
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('undeliverable', :from => 'status')
      within("select#product_type")do
        wait_until{
          assert page.has_content?('Kit')
          assert page.has_content?('Card')
          assert page.has_content?('Others')
        }
      end
    end
  end

  test "create a report fulfillment selecting OTHERS at product type." do
    setup_member(false)
    product = FactoryGirl.create(:product, :club_id => @club.id, :sku => 'kit-card')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => 'kit-card')

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    fulfillment = Fulfillment.find_by_product_sku('kit-card')
    within("#fulfillments_table")do
      check('_all_times')
      select('not_processed', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('not_processed') 
      }
    end
  end

  test "kit fulfillment without stock." do
    setup_member(false)
    product = Product.find_by_sku('KIT')
    product.update_attribute(:stock,0)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    fulfillment = Fulfillment.find_by_product_sku(product.sku)

    within("#fulfillments_table")do
      check('_all_times')
      select('out_of_stock', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('out_of_stock') 
      }
    end
  end

  test "Create a report fulfillment selecting KIT at product type." do
    setup_member(false)
    product = Product.find_by_sku('KIT')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id]).type_kit
    fulfillment = fulfillments.first
    
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    fulfillment = Fulfillment.find_by_product_sku(product.sku)

    within("#fulfillments_table")do
      select('not_processed', :from => 'status')
      select('Kit',:from => 'product_type')
    end

    csv_string = Fulfillment.generateCSV(fulfillments, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,ZIP,Product,Charter Member Status\n#{@saved_member.visible_id},#{@saved_member.first_name},#{@saved_member.last_name},'#{(I18n.l @saved_member.member_since_date, :format => :only_date_short)}','#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)}',#{@saved_member.address},#{@saved_member.city},#{@saved_member.zip},KIT,\n")

    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Kit',:from => 'product_type')
    end

    click_link_or_button 'Report'

    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('processing') 
        assert page.has_selector?('#mark_as_sent')
      }
      click_link_or_button('Mark as sent')
      wait_until{ assert page.has_content?("Fulfillment #{product.sku} was set as sent.") }
    end
    fulfillment.reload
    wait_until{ assert_equal(fulfillment.status,'sent') }
  end 

  test "change status of fulfillment CARD from not_processed to sent" do
    setup_member(false)
    product = Product.find_by_sku('CARD')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    @saved_member = Member.find_by_email(@member.email)

    fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id]).type_card
    fulfillment = fulfillments.first
    
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}

    fulfillment = Fulfillment.find_by_product_sku(product.sku)

    within("#fulfillments_table")do
      select('not_processed', :from => 'status')
      select('Card',:from => 'product_type')
    end

    csv_string = Fulfillment.generateCSV(fulfillments, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,ZIP,Product,Charter Member Status\n#{@saved_member.visible_id},#{@saved_member.first_name},#{@saved_member.last_name},'#{(I18n.l @saved_member.member_since_date, :format => :only_date_short)}','#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)}',#{@saved_member.address},#{@saved_member.city},#{@saved_member.zip},CARD,\n")

    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Card',:from => 'product_type')
    end

    click_link_or_button 'Report'
    within("#report_results")do
      wait_until{
        assert page.has_content?("#{fulfillment.member.visible_id}")
        assert page.has_content?(fulfillment.member.full_name)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?('processing') 
        assert page.has_selector?('#mark_as_sent')
      }
      click_link_or_button('Mark as sent')
      wait_until{ assert page.has_content?("Fulfillment #{product.sku} was set as sent.") }
    end
    fulfillment.reload
    wait_until{ assert_equal(fulfillment.status,'sent') }
  end 

  test "do not show fulfillment KIT with status = sent actions when member is lapsed." do
    setup_member(false)
    product = Product.find_by_sku('KIT')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    fulfillment = Fulfillment.last
    fulfillment.set_as_processing
    fulfillment.set_as_sent

    @saved_member = Member.find_by_email(@member.email)
    @saved_member.set_as_canceled

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('sent')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?((I18n.t('activerecord.attributes.member.is_lapsed')))
        assert page.has_no_selector?('#resend')
      }
    end
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('sent', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('sent')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?((I18n.t('activerecord.attributes.member.is_lapsed')))
        assert page.has_no_selector?('#resend')
      }
    end
  end

  test "do not show fulfillment CARD with status = sent actions when member is lapsed." do
    setup_member(false)
    product = Product.find_by_sku('CARD')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => product.sku)

    create_member_throught_sloop(enrollment_info)
    sleep(1)
    fulfillment = Fulfillment.last
    fulfillment.set_as_processing
    fulfillment.set_as_sent

    @saved_member = Member.find_by_email(@member.email)
    @saved_member.set_as_canceled

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('sent')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?((I18n.t('activerecord.attributes.member.is_lapsed')))
        assert page.has_no_selector?('#resend')
      }
    end
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('sent', :from => 'status')
      select('Card',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('sent')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_content?((I18n.t('activerecord.attributes.member.is_lapsed')))
        assert page.has_no_selector?('#resend')
      }
    end
  end

  test "not_processed and processing fulfillments should be updated to undeliverable when set_wrong_address" do
    setup_member(false)
    product_card = Product.find_by_sku('CARD')
    product_kit = Product.find_by_sku('KIT')
    product_other = FactoryGirl.create(:product, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product_other.sku},CARD,KIT")

    create_member_throught_sloop(enrollment_info)
    sleep(1)

    @saved_member = Member.find_by_email(@member.email)
    fulfillment_card = Fulfillment.find_by_product_sku(product_card.sku)
    fulfillment_kit = Fulfillment.find_by_product_sku(product_kit.sku)
    fulfillment_other = Fulfillment.find_by_product_sku(product_other.sku)
    fulfillment_other.set_as_processing
    @saved_member.set_wrong_address(@admin_agent, 'reason')

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('undeliverable', :from => 'status')
      select('Card',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('undeliverable')
        assert page.has_content?(product_card.sku)
        assert page.has_content?((I18n.t('activerecord.attributes.member.undeliverable')))
      }
    end
    within("#fulfillments_table")do
      check('_all_times')
      select('undeliverable', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('undeliverable')
        assert page.has_content?(product_kit.sku)
        assert page.has_content?((I18n.t('activerecord.attributes.member.undeliverable')))
        assert page.has_no_selector?('#resend')
      }
    end
    within("#fulfillments_table")do
      check('_all_times')
      select('undeliverable', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('undeliverable')
        assert page.has_content?(product_other.sku)
        assert page.has_content?((I18n.t('activerecord.attributes.member.undeliverable')))
        assert page.has_no_selector?('#resend')
      }
    end
  end

  test "kit and card renewed fulfillments should not set as undeliverable" do
    setup_member(false)
    product_card = Product.find_by_sku('CARD')
    product_kit = Product.find_by_sku('KIT')
    product_other = FactoryGirl.create(:product, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product_other.sku},CARD,KIT")

    create_member_throught_sloop(enrollment_info)
    @saved_member = Member.find_by_email(@member.email)
    fulfillment_card = Fulfillment.find_by_product_sku(product_card.sku)
    fulfillment_kit = Fulfillment.find_by_product_sku(product_kit.sku)
    fulfillment_card.update_attribute(:renewed, true)
    fulfillment_kit.update_attribute(:renewed, true)

    @saved_member.set_wrong_address(@admin_agent,'reason')

    visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('not_processed', :from => 'status')
      select('Card',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('not_processed')
        assert page.has_content?(product_card.sku)
        assert page.has_content?((I18n.t('activerecord.attributes.fulfillment.renewed')))
      }
    end
    
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('not_processed', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('not_processed')
        assert page.has_content?(product_kit.sku)
        assert page.has_content?((I18n.t('activerecord.attributes.fulfillment.renewed')))
      }
    end
  end

  test "fulfillment record at not_processed status - recurrent = false" do
    setup_member(false)
    product = FactoryGirl.create(:product_without_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_member_throught_sloop(enrollment_info)
    @saved_member = Member.find_by_email(@member.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    wait_until{
      assert_equal((I18n.l(fulfillment.assigned_at, :format => :long)),(I18n.l(fulfillment.member.join_date, :format => :long)))
      assert_equal(fulfillment.renewable_at,nil)
      assert_equal(fulfillment.status,'not_processed')
      assert_equal(fulfillment.recurrent,false)
    }
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('not_processed', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('not_processed')
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
      }
    end
    fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id]).type_others

    csv_string = Fulfillment.generateCSV(fulfillments, true) 
    assert_equal(csv_string, "PackageId,Costcenter,Companyname,Address,City,State,Zip,Endorsement,Packagetype,Divconf,Bill Transportation,Weight,UPS Service\n#{fulfillment.tracking_code},Costcenter,#{@saved_member.full_name},#{@saved_member.address},#{@saved_member.city},#{@saved_member.state},#{@saved_member.zip},Return Service Requested,Irregulars,Y,Shipper,,MID\n")
  
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('processing')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_selector?("#mark_as_sent")
      }
    end
  end

  test "fulfillment record at not_processed status - recurrent = true" do
    setup_member(false)
    product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_member_throught_sloop(enrollment_info)
    @saved_member = Member.find_by_email(@member.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    wait_until{
      assert_equal((I18n.l(fulfillment.assigned_at, :format => :long)),(I18n.l(fulfillment.member.join_date, :format => :long)))
      assert_equal((I18n.l(fulfillment.renewable_at, :format => :long)),(I18n.l(fulfillment.assigned_at + 1.year, :format => :long)))
      assert_equal(fulfillment.status,'not_processed')
      assert_equal(fulfillment.recurrent,true)
    }
    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('not_processed', :from => 'status')
      select('Others',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('not_processed')
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
      }
    end
    fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id]).type_others

    csv_string = Fulfillment.generateCSV(fulfillments, true) 
    assert_equal(csv_string, "PackageId,Costcenter,Companyname,Address,City,State,Zip,Endorsement,Packagetype,Divconf,Bill Transportation,Weight,UPS Service\n#{fulfillment.tracking_code},Costcenter,#{@saved_member.full_name},#{@saved_member.address},#{@saved_member.city},#{@saved_member.state},#{@saved_member.zip},Return Service Requested,Irregulars,Y,Shipper,,MID\n")
  
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('processing')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_selector?("#mark_as_sent")
      }
    end
  end

  test "Generate CSV with fulfillment at processing status." do
    setup_member(false)
    product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_member_throught_sloop(enrollment_info)
    @saved_member = Member.find_by_email(@member.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    
    fulfillment.set_as_processing

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Fulfillments")
    end
    within("#fulfillments")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('processing')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_selector?("#mark_as_sent")
      }
    end

    fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', 'processing', @club.id).type_others
    csv_string = Fulfillment.generateCSV(fulfillments, true) 
    assert_equal(csv_string, "PackageId,Costcenter,Companyname,Address,City,State,Zip,Endorsement,Packagetype,Divconf,Bill Transportation,Weight,UPS Service\n#{fulfillment.tracking_code},Costcenter,#{@saved_member.full_name},#{@saved_member.address},#{@saved_member.city},#{@saved_member.state},#{@saved_member.zip},Return Service Requested,Irregulars,Y,Shipper,,MID\n")
  end

  test "change status of fulfillment KIT from not_processed to undeliverable" do
    setup_member(false)
    product = Product.find_by_sku('KIT')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_member_throught_sloop(enrollment_info)
    @saved_member = Member.find_by_email(@member.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('not_processed', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('not_processed')
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
      }
    end
    fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id]).type_kit

    csv_string = Fulfillment.generateCSV(fulfillments, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,ZIP,Product,Charter Member Status\n#{@saved_member.visible_id},#{@saved_member.first_name},#{@saved_member.last_name},'#{(I18n.l @saved_member.member_since_date, :format => :only_date_short)}','#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)}',#{@saved_member.address},#{@saved_member.city},#{@saved_member.zip},#{product.sku},\n")
  
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Kit',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('processing')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_selector?("#mark_as_sent")
        assert page.has_selector?('#set_as_wrong_address')
      }
      click_link_or_button('Set as wrong address')
      wait_until{ page.has_selector?('#reason') }
      fill_in 'reason', :with => 'spam'
      confirm_ok_js
      click_link_or_button('Set wrong address')
      wait_until{ page.has_content?("#{fulfillment.member.full_address} is undeliverable. Reason: spam") }
    end
    fulfillment.reload
    wait_until{ assert_equal(fulfillment.status,'undeliverable') }
  end

  test "change status of fulfillment CARD from not_processed to undeliverable" do
    setup_member(false)
    product = Product.find_by_sku('CARD')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_member_throught_sloop(enrollment_info)
    @saved_member = Member.find_by_email(@member.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)

    click_link_or_button("My Clubs")
    within("#my_clubs_table"){wait_until{click_link_or_button("Fulfillments")}}
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('not_processed', :from => 'status')
      select('Card',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?('not_processed')
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?(fulfillment.tracking_code)
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
      }
    end
    fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', Date.today, Date.today, @club.id]).type_card

    csv_string = Fulfillment.generateCSV(fulfillments, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,ZIP,Product,Charter Member Status\n#{@saved_member.visible_id},#{@saved_member.first_name},#{@saved_member.last_name},'#{(I18n.l @saved_member.member_since_date, :format => :only_date_short)}','#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)}',#{@saved_member.address},#{@saved_member.city},#{@saved_member.zip},#{product.sku},\n")
  
    wait_until{page.has_content?("Fulfillments")}
    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Card',:from => 'product_type')
    end
    click_link_or_button('Report')
    within("#report_results")do
      wait_until{
        assert page.has_content?(fulfillment.product_sku)
        assert page.has_content?('processing')
        assert page.has_content?((I18n.l(fulfillment.assigned_at, :format => :long)))
        assert page.has_content?((I18n.l(fulfillment.renewable_at, :format => :long)))
        assert page.has_selector?("#mark_as_sent")
        assert page.has_selector?('#set_as_wrong_address')
      }
      click_link_or_button('Set as wrong address')
      wait_until{ page.has_selector?('#reason') }
      fill_in 'reason', :with => 'spam'
      confirm_ok_js
      click_link_or_button('Set wrong address')
      wait_until{ page.has_content?("#{fulfillment.member.full_address} is undeliverable. Reason: spam") }
    end
    fulfillment.reload
    wait_until{ assert_equal(fulfillment.status,'undeliverable') }
  end

  test "create a report fulfillment selecting KIT at product type - Chapter member status" do
    setup_member(false)
    product = Product.find_by_sku('KIT')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_member_throught_sloop(enrollment_info)
    @saved_member = Member.find_by_email(@member.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    fulfillment.set_as_processing

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    click_link_or_button 'Edit'
    wait_until{ select('VIP', :from => 'member_member_group_type_id') }
    alert_ok_js
    click_link_or_button 'Update Member'

    visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Kit',:from => 'product_type')
    end

    click_link_or_button 'Report'
    fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'processing', Date.today, Date.today, @club.id]).type_kit
    csv_string = Fulfillment.generateCSV(fulfillments, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,ZIP,Product,Charter Member Status\n#{@saved_member.visible_id},#{@saved_member.first_name},#{@saved_member.last_name},'#{(I18n.l @saved_member.member_since_date, :format => :only_date_short)}','#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)}',#{@saved_member.address},#{@saved_member.city},#{@saved_member.zip},#{product.sku},C\n")    
  end

  test "Create a report fulfillment selecting CARD at product type - Chapter member status" do
    setup_member(false)
    product = Product.find_by_sku('CARD')
    enrollment_info = FactoryGirl.build(:enrollment_info, :product_sku => "#{product.sku}")

    create_member_throught_sloop(enrollment_info)
    @saved_member = Member.find_by_email(@member.email)
    fulfillment = Fulfillment.find_by_product_sku(product.sku)
    fulfillment.set_as_processing

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    click_link_or_button 'Edit'
    wait_until{ select('VIP', :from => 'member_member_group_type_id') }
    alert_ok_js
    click_link_or_button 'Update Member'

    visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#fulfillments_table")do
      check('_all_times')
      select('processing', :from => 'status')
      select('Card',:from => 'product_type')
    end

    click_link_or_button 'Report'
    fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'processing', Date.today, Date.today, @club.id]).type_card
    csv_string = Fulfillment.generateCSV(fulfillments, false) 
    assert_equal(csv_string, "Member Number,Member First Name,Member Last Name,Member Since Date,Member Expiration Date,ADDRESS,CITY,ZIP,Product,Charter Member Status\n#{@saved_member.visible_id},#{@saved_member.first_name},#{@saved_member.last_name},'#{(I18n.l @saved_member.member_since_date, :format => :only_date_short)}','#{(I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at)}',#{@saved_member.address},#{@saved_member.city},#{@saved_member.zip},#{product.sku},C\n")    
  end

end
