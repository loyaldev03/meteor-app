require 'test_helper'
 
class MembersClubCashTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    @saved_member = FactoryGirl.create(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent)

		@saved_member.reload
		
    sign_in_as(@admin_agent)
   end


  test "add club cash amount" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    click_on 'Add club cash'
    
    alert_ok_js
    fill_in '[amount]', :with => "15"  
    click_on 'Save club cash transaction'
    within("#td_mi_club_cash_amount") { assert page.has_content?("15") }

    within("#operations_table") do
      wait_until {
        assert page.has_content?("15 club cash was successfully added")
      }
    end

    click_on 'Add club cash'
    
    alert_ok_js
    fill_in '[amount]', :with => "-5"  
    click_on 'Save club cash transaction'
    within("#td_mi_club_cash_amount") { assert page.has_content?("10") }

    within("#operations_table") do
      wait_until {
        assert page.has_content?("5 club cash was successfully deducted")
      }
    end

  end


  test "club cash amount can't be negatibe" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    click_on 'Add club cash'
    
    alert_ok_js
    fill_in '[amount]', :with => "15"  
    click_on 'Save club cash transaction'
    
    within("#td_mi_club_cash_amount") { assert page.has_content?("15") }

    click_on 'Add club cash'
    fill_in '[amount]', :with => "-20"
    alert_ok_js
    click_on 'Save club cash transaction'

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#td_mi_club_cash_amount") { assert page.has_content?("15") }

  end


end