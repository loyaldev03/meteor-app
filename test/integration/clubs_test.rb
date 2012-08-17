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
    sleep(20)
    assert page.has_content?("The club #{unsaved_club.name} was successfully created")
  end


end