require 'test_helper' 
 
class ClubTest < ActionController::IntegrationTest
 
  setup do
    init_test_setup
    @partner = FactoryGirl.create(:partner)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  test "create club" do
    unsaved_club = FactoryGirl.build(:simple_club)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[api_username]', :with => unsaved_club.api_username
    fill_in 'club[api_password]', :with => unsaved_club.api_password
    attach_file('club[logo]', "#{Rails.root}/test/integration/test_img.png")
    check('club[requires_external_id]')
    select('application', :from => 'club[theme]')
    assert_difference('Club.count') do
      click_link_or_button 'Create Club'
    end
    assert page.has_content?("The club #{unsaved_club.name} was successfully created")
  end

  test "create blank club" do
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    click_link_or_button 'Create Club'
    assert page.has_content?("can't be blank")
  end

  test "should read club" do
    saved_club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    visit clubs_path(@partner.prefix)
    within("#clubs_table") do
      wait_until{
        assert page.has_content?(saved_club.id.to_s)
        assert page.has_content?(saved_club.name)
        assert page.has_content?(saved_club.description)
      }
    end
  end
 
end