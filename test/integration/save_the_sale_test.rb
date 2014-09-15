require 'test_helper'

class SaveTheSaleTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
  end

  def setup_user(approval = false, active = false)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_gateway2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'second_tom_without_aproval')
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    @terms_of_membership_with_approval2 = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id, :name => 'second_tom_aproval')
    @new_terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_hold_card, :club_id => @club.id)
    @lifetime_terms_of_membership = FactoryGirl.create(:life_time_terms_of_membership, :club_id => @club.id)
    
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)
    
    unsaved_user = FactoryGirl.build(:user_with_api)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)

    if approval
      create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_approval)
    else
      create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    end
    @saved_user = User.find_by_email(unsaved_user.email)
    @saved_user.set_as_provisional if @saved_user.can_be_approved?

    if active
		  @saved_user.set_as_active
    end
    
    @old_membership = @saved_user.current_membership
    sign_in_as(@admin_agent)
  end

  ###########################################################
  # TESTS
  ###########################################################

  
  test "save the sale from active to provisional with enrollment info related to product not available at inventory" do
    setup_user(false, true)
    assert_equal @saved_user.status, "active"
    
    prods = Product.find_all_by_sku @saved_user.enrollment_infos.first.product_sku.split(',')
    prods.each {|p| p.delete }

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
      end
    end
  end

  test "save the sale from active to provisional with enrollment info related to product without stock" do
    setup_user(false, true)
    assert_equal @saved_user.status, "active"
    
    prods = Product.find_all_by_sku @saved_user.enrollment_infos.first.product_sku.split(',')
    prods.each do |p| 
      p.stock = 0 
      p.allow_backorder = false
      p.save
    end

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
      end
    end
  end

  test "save the sale from active to provisional with enrollment info related to product available at inventory" do
    setup_user(false, true)
    assert_equal @saved_user.status, "active"
    
    prods = Product.find_all_by_sku @saved_user.enrollment_infos.first.product_sku.split(',')
    prods.each do |p| 
      p.stock = 0 
      p.allow_backorder = false
      p.save
    end

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
      end
    end
  end

  test "save the sale from provisional to provisional" do
    setup_user
    assert_equal @saved_user.status, "provisional"
    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
      end
    end
  end

  test "save the sale from active to provisional" do
    setup_user(false, true)
    assert_equal @saved_user.status, "active"
    
    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
      end
    end
  end

  test "save the sale with the same TOM" do
    setup_user(false,true)
    assert_equal @saved_user.status, "active"
      
    assert_difference('Membership.count',0) do 
      assert_difference('EnrollmentInfo.count',0) do
        save_the_sale(@saved_user, @saved_user.current_membership.terms_of_membership, false)
      end
    end
    assert page.has_content?("Nothing to change. Member is already enrolled on that TOM")
  end

  test "Save the sale from TOM without approval to TOM without approval - status active" do
    setup_user(false,true)

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @terms_of_membership_with_gateway2)
      end
    end
  end

  test "Save the sale from TOM without approval to TOM without approval - status provisional" do
    setup_user
    assert_equal @saved_user.status, "provisional"

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @terms_of_membership_with_gateway2)
      end
    end
  end

  test "Save the sale from TOM without approval to TOM approval - status active" do
    setup_user(false,true)

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @terms_of_membership_with_approval)
      end
    end
  end

  test "Save the sale from TOM without approval to TOM approval - status provisional" do
    setup_user
    assert_equal @saved_user.status, "provisional"

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @terms_of_membership_with_approval)
      end
    end
  end

  test "Save the sale from TOM approval to TOM without approval - status active" do
    setup_user(true,true)
    assert_equal @saved_user.status, "active"

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @terms_of_membership_with_gateway)
      end
    end
  end

  test "Save the sale from TOM approval to TOM without approval - status provisional" do
    setup_user(true,false)
    assert_equal @saved_user.status, "provisional"

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @terms_of_membership_with_gateway2)
      end
    end
  end

  test "Save the sale from TOM approval to TOM approval - status active" do
    setup_user(true,true)
    assert_equal @saved_user.status, "active"

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @terms_of_membership_with_approval2)
      end
    end
  end

  test "Save the sale from TOM approval to TOM approval - status provisional" do
    setup_user(true,false)

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @terms_of_membership_with_approval2)
      end
    end
  end

  test "user full save" do
    setup_user
    @saved_user.bill_membership
    
    visit user_save_the_sale_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id, :transaction_id => Transaction.last.id)
    click_on 'Full save'
     
    assert page.has_content?("Full save done")
    
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations_table") do 
        assert page.has_content?("Full save done")
    end
  end 

  test "Change the user from a lifetime TOM to a another" do
    setup_user(false)

    unsaved_user = FactoryGirl.build(:user_with_cc, :club_id => @club.id)
    @saved_user = create_user(unsaved_user, nil, @lifetime_terms_of_membership.name, true)

    assert_difference('Membership.count') do 
      assert_difference('EnrollmentInfo.count') do
        save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
      end
    end

    validate_view_user_base(@saved_user)
  end
end