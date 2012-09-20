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


end