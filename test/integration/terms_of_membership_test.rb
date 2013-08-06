require 'test_helper'

class TermsOfMembershipTests < ActionController::IntegrationTest

  setup do
		init_test_setup
		@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
		@partner = FactoryGirl.create(:partner)
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
		sign_in_as(@admin_agent)
	end

	test "Delete unused TOM" do
		13.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
		the_tom = TermsOfMembership.last
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.id.to_s) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was successfully destroyed.")
	end

	test "Do not delete a TOM with inactive memberships" do
		27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_lapsed_member = create_active_member(the_tom, :lapsed_member, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.id.to_s) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was not destroyed.")
	end

	test "Do not delete a TOM with active memberships" do
		27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_active_member = create_active_member(the_tom, :active_member, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.id.to_s) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was not destroyed.")
	end

end