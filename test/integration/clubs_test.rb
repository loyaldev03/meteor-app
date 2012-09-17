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

  test "should update club" do
    saved_club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    visit clubs_path(@partner.prefix)
    within("#clubs_table") do
      wait_until{
        click_link_or_button 'Edit'
      }
    end
      fill_in 'club[name]', :with => 'another name'
      fill_in 'club[api_username]', :with => 'another api username'
      fill_in 'club[api_password]', :with => 'another api password'
      fill_in 'club[description]', :with => 'new description'
      attach_file('club[logo]', "#{Rails.root}/test/integration/test_img.png")
      check('club[requires_external_id]')
      select('application', :from => 'club[theme]')
      click_link_or_button 'Update'
      saved_club.reload
      assert page.has_content?(" The club #{saved_club.name} was successfully updated.")
      assert_equal saved_club.name, 'another name'
      assert_equal saved_club.api_username, 'another api username'
      assert_equal saved_club.api_password, 'another api password'
      assert_equal saved_club.description, 'new description'
  end

  test "should delete club" do
    saved_club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    visit clubs_path(@partner.prefix)
    confirm_ok_js
    within("#clubs_table") do
      wait_until{
        click_link_or_button 'Destroy'
      }
    end
    assert !page.has_content?(saved_club.name)
    assert Club.with_deleted.where(:id => saved_club.id).first
  end

  test "should create default product when creating club" do
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
    click_link_or_button 'Back'
    within("#clubs_table") do
      wait_until{
        click_link_or_button 'Products'
      }
    end
    within("#products_table") do
      wait_until{
        assert page.has_content?('KIT')
        assert page.has_content?('CARD')
      }
    end
  end

  test "should see all clubs as admin on my clubs section" do
    10.times{ FactoryGirl.create(:simple_club, :partner_id => @partner.id) }
    within("#partners_table") do
      wait_until{
        assert page.has_content?('Show')
        assert page.has_content?('Edit')
        assert page.has_content?('Dashboard')
        assert page.has_content?('Destroy')
      }
    end
    visit admin_agent_my_clubs_path(@admin_agent.id)
    within("#my_clubs_table") do
      wait_until{
        Club.all.each do |club|
          assert page.has_content?(club.name)
        end
      }
    end
  end
end