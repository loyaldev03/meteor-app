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
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)
    FactoryGirl.create(:batch_agent)

    if create_new_member
	    @saved_member = FactoryGirl.create(:active_member, 
	      :club_id => @club.id, 
	      :terms_of_membership => @terms_of_membership_with_gateway,
	      :created_by => @admin_agent)

			@saved_member.reload
		end

    sign_in_as(@admin_agent)
  end

  test "cancel member and check if not_processed fulfillments were updated to canceled" do
    setup_member
    fulfillment = FactoryGirl.create(:fulfillment, :member_id => @saved_member.id)
    
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
    fulfillment.reload
    assert_equal fulfillment.status, 'canceled'
  end

  test "cancel member and check if processing fulfillments were updated to canceled" do
    setup_member
    fulfillment = FactoryGirl.create(:fulfillment, :member_id => @saved_member.id)
    fulfillment.set_as_processing

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
    fulfillment.reload
    assert_equal fulfillment.status, 'canceled'
  end
end