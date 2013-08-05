require 'test_helper'

class TermsOfMembershipTests < ActionController::IntegrationTest

  setup do
		init_test_setup
		@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
		@partner = FactoryGirl.create(:partner)
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
		sign_in_as(@admin_agent)
	end

	test "Delete unused tom" do
		the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			click_link_or_button 'Destroy'
		end
		page.driver.browser.switch_to.alert.accept
		assert page.has_content?("was successfully destroyed.")
	end

	test "Do not delete a TOM with inactive memberships" do
		the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
		the_lapsed_member = FactoryGirl.create(:lapsed_member, :club_id => @club.id)
		the_membership = FactoryGirl.create(:lapsed_member_membership, :member_id => the_lapsed_member.id, :terms_of_membership_id => the_tom.id)

		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			click_link_or_button 'Destroy'
		end
		page.driver.browser.switch_to.alert.accept
		assert page.has_content?("was not destroyed.")
	end

	test "Do not delete a TOM with active memberships" do
		the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
		the_active_member = FactoryGirl.create(:active_member, :club_id => @club.id)
		the_membership = FactoryGirl.create(:applied_member_membership, :member_id => the_active_member.id, :terms_of_membership_id => the_tom.id)

		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			click_link_or_button 'Destroy'
		end
		page.driver.browser.switch_to.alert.accept
		assert page.has_content?("was not destroyed.")
	end

end