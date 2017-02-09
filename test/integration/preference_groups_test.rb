require 'test_helper'

class PreferenceGroupTest < ActionDispatch::IntegrationTest
 
  setup do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)    
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @preference_group = FactoryGirl.create(:preference_group, :club_id => @club.id)  
    sign_in_as(@admin_agent)  
  end

  def fill_in_form(name, code)
    fill_in 'preference_group[name]', with: name
    fill_in 'preference_group[code]', with: code
    check('preference_group[add_by_default]')
  end

  test 'create preference group' do
    unsaved_preference_group = FactoryGirl.build(:preference_group, :club_id => @club.id)
    visit preference_groups_path(@partner.prefix, @club.name)
    click_link_or_button 'New Preference Group'
    fill_in_form(unsaved_preference_group.name, unsaved_preference_group.code)
    click_link_or_button 'Create Preference group'
    assert page.has_content?("Preference Group was successfully created.")
  end

  test 'show preference group' do        
    visit preference_groups_path(@partner.prefix, @club.name)
    within("#preference_groups_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?(@preference_group.name)
    assert page.has_content?(@preference_group.code) 
  end

  test 'update preference group' do
    unsaved_preference_group = FactoryGirl.build(:preference_group, :club_id => @club.id)    
    visit preference_groups_path(@partner.prefix, @club.name)
    within("#preference_groups_table") do
      click_link_or_button 'Edit'
    end
    fill_in 'preference_group[name]', with: name
    check('preference_group[add_by_default]')
    click_link_or_button 'Update Preference group'
    assert page.has_content?("Preference Group was successfully updated.")
  end
end
