require 'test_helper'

class PreferenceTest < ActionDispatch::IntegrationTest
 
  setup do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)    
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @preference_group = FactoryGirl.create(:preference_group, :club_id => @club.id)  
    @preference = FactoryGirl.create(:preference, :preference_group_id => @preference_group.id)      
    sign_in_as(@admin_agent)
  end

  test 'see preferences' do 
    visit preference_groups_path(@partner.prefix, @club.name)
    within("#preference_groups_table") do
      click_link_or_button 'Preferences'      
    end
    assert page.has_content?("Preferences")
  end

  test 'create preference' do    
    unsaved_preference = FactoryGirl.build(:preference, :preference_group_id => @preference_group.id)    
    visit preference_group_preferences_path(@partner.prefix, @club.name, @preference_group.id)
    click_link_or_button 'New Preference'  
    fill_in 'preference[name]', with: unsaved_preference.name
    click_link_or_button 'Create Preference' 
    assert page.has_content?("Preference #{unsaved_preference.name} added successfully.")
  end

  test 'update preferences' do    
    unsaved_preference = FactoryGirl.build(:preference, :preference_group_id => @preference_group.id)    
    visit preference_group_preferences_path(@partner.prefix, @club.name, @preference_group.id)
    within("#preferencesTable") do
      click_link_or_button 'Edit'
    end
    fill_in 'preference[name]', with: unsaved_preference.name
    click_link_or_button 'Update Preference'
    assert page.has_content?("Preference updated successfully.")
  end

  test 'delete preferences' do    
    visit preference_group_preferences_path(@partner.prefix, @club.name, @preference_group.id)
    within("#preferencesTable") do
      click_link_or_button 'Destroy'
    end
    click_link_or_button 'Confirm'
    assert page.has_content?("Preference was successfully deleted.")
  end
end