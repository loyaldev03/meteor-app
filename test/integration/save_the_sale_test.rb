require 'test_helper'

class SaveTheSaleTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member(create_provisional = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_gateway2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'second_tom_without_aproval')
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    @terms_of_membership_with_approval2 = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id, :name => 'second_tom_aproval')
    @new_terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_hold_card, :club_id => @club.id)
    
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)
    FactoryGirl.create(:batch_agent)
    
    @saved_member = nil
    
    if create_provisional
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc, nil, {}, { :created_by => @admin_agent })
    else
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })			
		end
    @saved_member.reload
    sign_in_as(@admin_agent)
  end

  test "save the sale from provisional to provisional" do
    setup_member(true)
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'    

    select(@new_terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on 'Save the sale'

    @saved_member.reload

    assert page.has_content?("Save the sale succesfully applied")
    
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member enrolled successfully")
        assert page.has_content?("Save the sale from TOMID #{@terms_of_membership_with_gateway.id} to TOMID #{@new_terms_of_membership_with_gateway.id}")
      }
    end
  end

  test "save the sale from active to provisional" do
    setup_member(false)
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'    

    select(@new_terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on 'Save the sale'

    @saved_member.reload

    assert page.has_content?("Save the sale succesfully applied")
    
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member enrolled successfully")
        assert page.has_content?("Save the sale from TOMID #{@terms_of_membership_with_gateway.id} to TOMID #{@new_terms_of_membership_with_gateway.id}")
      }
    end

  end

  test "save the sale with the same TOM" do
    setup_member(false)
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'    

    select(@terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on 'Save the sale'

    assert page.has_content?("Nothing to change. Member is already enrolled on that TOM")
  end

  test "Save the sale from TOM without approbal to TOM without aprobal - status active" do
    setup_member(false)
    @saved_member.set_as_active

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'   

    select(@terms_of_membership_with_gateway2.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on 'Save the sale'

    wait_until{ assert page.has_content?("Save the sale succesfully applied") }
  end

  test "Save the sale from TOM without approbal to TOM without aprobal - status provisional" do
    setup_member(false)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'   

    select(@terms_of_membership_with_gateway2.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on 'Save the sale'

    wait_until{ assert page.has_content?("Save the sale succesfully applied") }
  end

  test "Save the sale from TOM without approbal to TOM aprobal - status active" do
    setup_member(false)
    @saved_member.set_as_active

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'   

    wait_until{ select(@terms_of_membership_with_approval.name, :from => 'terms_of_membership_id') }
    confirm_ok_js
    click_on 'Save the sale'

    wait_until{ assert page.has_content?("Save the sale succesfully applied") }
  end

  test "Save the sale from TOM without approbal to TOM aprobal - status provisional" do
    setup_member(false)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'   

    wait_until{ select(@terms_of_membership_with_approval.name, :from => 'terms_of_membership_id') }
    confirm_ok_js
    click_on 'Save the sale'

    wait_until{ assert page.has_content?("Save the sale succesfully applied") }
  end

  test "Save the sale from TOM approbal to TOM without aprobal - status active" do
    setup_member
    @saved_member.set_as_active

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'   

    wait_until{ select(@terms_of_membership_with_gateway2.name, :from => 'terms_of_membership_id') }
    confirm_ok_js
    click_on 'Save the sale'

    wait_until{ assert page.has_content?("Save the sale succesfully applied") }
  end

  test "Save the sale from TOM approbal to TOM without aprobal - status provisional" do
    setup_member

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'   

    wait_until{ select(@terms_of_membership_with_gateway2.name, :from => 'terms_of_membership_id') }
    confirm_ok_js
    click_on 'Save the sale'

    wait_until{ assert page.has_content?("Save the sale succesfully applied") }
  end

  test "Save the sale from TOM approbal to TOM aprobal - status active" do
    setup_member
    @saved_member.set_as_active

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'   

    wait_until{ select(@terms_of_membership_with_approval2.name, :from => 'terms_of_membership_id') }
    confirm_ok_js
    click_on 'Save the sale'

    wait_until{ assert page.has_content?("Save the sale succesfully applied") }
  end

  test "Save the sale from TOM approbal to TOM aprobal - status provisional" do
    setup_member

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Save the sale'   

    wait_until{ select(@terms_of_membership_with_approval2.name, :from => 'terms_of_membership_id') }
    confirm_ok_js
    click_on 'Save the sale'

    wait_until{ assert page.has_content?("Save the sale succesfully applied") }
  end
end