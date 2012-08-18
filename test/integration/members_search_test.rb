require 'test_helper' 
 
class MembersSearchTest < ActionController::IntegrationTest
 
  setup do
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
    10.times{ FactoryGirl.create(:active_member, :club_id => @club.id, :terms_of_membership => @terms_of_membership_with_gateway) }
    @search_member = Member.first
    sign_in_as(@admin_agent)
  end

  def search_member(field_selector, value, validate_text)
    fill_in field_selector, :with => value
    click_on 'Search'
    within("#members") do
      wait_until {
        assert page.has_content?(validate_text)
      }
    end
  end
  
  test "search member by member id" do
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    search_member("member[member_id]", "#{@search_member.visible_id}", @search_member.full_name)
  end

  test "search member by first name" do
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    search_member("member[first_name]", "#{@search_member.first_name}", @search_member.full_name)
  end


end