require 'test_helper'

class SaveTheSaleTest < ActionDispatch::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
  end

  def setup_user(approval = false, active = false)
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @terms_of_membership_with_gateway2 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'second_tom_without_aproval')
    @terms_of_membership_with_approval = FactoryBot.create(:terms_of_membership_with_gateway_needs_approval, club_id: @club.id)
    @terms_of_membership_with_approval2 = FactoryBot.create(:terms_of_membership_with_gateway_needs_approval, club_id: @club.id, name: 'second_tom_aproval')
    @new_terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_hold_card, club_id: @club.id)
    @lifetime_terms_of_membership = FactoryBot.create(:life_time_terms_of_membership, club_id: @club.id)
    
    @member_cancel_reason =  FactoryBot.create(:member_cancel_reason)
    
    unsaved_user = FactoryBot.build(:user_with_api)
    credit_card = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)

    if approval
      create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_approval)
    else
      create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    end
    @saved_user = User.find_by(email: unsaved_user.email)
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
    
    product = @saved_user.current_membership.product
    product.delete

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
    end
  end

  test "save the sale from active to provisional with enrollment info related to product without stock" do
    setup_user(false, true)
    assert_equal @saved_user.status, "active"
    
    product = @saved_user.current_membership.product
    product.stock = 0 
    product.allow_backorder = false
    product.save

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
    end
  end

  test "save the sale from active to provisional with enrollment info related to product available at inventory" do
    setup_user(false, true)
    assert_equal @saved_user.status, "active"
    
    product = @saved_user.current_membership.product
    product.stock = 0 
    product.allow_backorder = false
    product.save

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
    end
  end

  test "save the sale from provisional to provisional" do
    setup_user
    assert_equal @saved_user.status, "provisional"
    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
    end
  end

  test "save the sale from active to provisional" do
    setup_user(false, true)
    assert_equal @saved_user.status, "active"
    
    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
    end
  end

  test "save the sale with the same TOM" do
    setup_user(false,true)
    assert_equal @saved_user.status, "active"
      
    assert_difference('Membership.count',0) do 
      save_the_sale(@saved_user, @saved_user.current_membership.terms_of_membership, nil, false, false)
    end
    assert page.has_content?("Nothing to change. Member is already enrolled on that TOM")
  end

  test "Save the sale from TOM without approval to TOM without approval - status active" do
    setup_user(false,true)

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @terms_of_membership_with_gateway2)
    end
  end

  test "Save the sale from TOM without approval to TOM without approval - status provisional" do
    setup_user
    assert_equal @saved_user.status, "provisional"

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @terms_of_membership_with_gateway2)
    end
  end

  test "Save the sale from TOM without approval to TOM approval - status active" do
    setup_user(false,true)

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @terms_of_membership_with_approval)
    end
  end

  test "Save the sale from TOM without approval to TOM approval - status provisional" do
    setup_user
    assert_equal @saved_user.status, "provisional"

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @terms_of_membership_with_approval)
    end
  end

  test "Save the sale from TOM approval to TOM without approval - status active" do
    setup_user(true,true)
    assert_equal @saved_user.status, "active"

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @terms_of_membership_with_gateway)
    end
  end

  test "Save the sale from TOM approval to TOM without approval - status provisional" do
    setup_user(true,false)
    assert_equal @saved_user.status, "provisional"

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @terms_of_membership_with_gateway2)
    end
  end

  test "Save the sale from TOM approval to TOM approval - status active" do
    setup_user(true,true)
    assert_equal @saved_user.status, "active"

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @terms_of_membership_with_approval2)
    end
  end

  test "Save the sale from TOM approval to TOM approval - status provisional" do
    setup_user(true,false)

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @terms_of_membership_with_approval2)
    end
  end

  test "user full save" do
    setup_user
    @saved_user.bill_membership
    
    visit user_save_the_sale_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, transaction_id: Transaction.last.id)
    click_on 'Full save'
     
    assert page.has_content?("Full save done")
    
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations_table") do 
        assert page.has_content?("Full save done")
    end
  end 

  test "Change the user from a lifetime TOM to a another" do
    setup_user(false)

    unsaved_user = FactoryBot.build(:user_with_cc, club_id: @club.id)
    @saved_user = create_user(unsaved_user, nil, @lifetime_terms_of_membership.name, true)

    assert_difference('Membership.count') do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
    end

    validate_view_user_base(@saved_user)
  end

  test "save the sale with remove club cash option as true" do
    setup_user
    assert_difference('Membership.count', 1) do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway, nil, true)
    end
    @saved_user.reload
    assert_equal @saved_user.club_cash_amount, 0
  end

  test "schedule save the sale - club cash remove as true" do
    setup_user
    schedule_date = Time.current.to_date + 2.days
    assert_difference('Membership.count', 0) do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway, schedule_date, true, false)
    end
    @saved_user.reload
    assert_equal @saved_user.change_tom_date, schedule_date
    assert_equal @saved_user.change_tom_attributes, {'remove_club_cash' => true, 'terms_of_membership_id' => @new_terms_of_membership_with_gateway.id, 'agent_id' => @admin_agent.id}
    assert @saved_user.club_cash_amount != 0
  
    within('#td_mi_future_tom_change') do
      assert page.has_content? schedule_date
      click_on 'Details'
      assert page.has_content? @new_terms_of_membership_with_gateway.name
    end
  end

  test "schedule save the sale - club cash remove as false" do
    setup_user
    schedule_date = Time.current.to_date + 2.days
    assert_difference('Membership.count', 0) do 
      save_the_sale(@saved_user, @new_terms_of_membership_with_gateway, schedule_date, false, false)
    end
    @saved_user.reload
    assert_equal @saved_user.change_tom_date, schedule_date
    assert_equal @saved_user.change_tom_attributes, {'remove_club_cash' => false, 'terms_of_membership_id' => @new_terms_of_membership_with_gateway.id, 'agent_id' => @admin_agent.id}
    assert @saved_user.club_cash_amount != 0
  
    within('#td_mi_future_tom_change') do
      assert page.has_content? schedule_date
      click_on 'Details'
      assert page.has_content? @new_terms_of_membership_with_gateway.name
    end
  end
end