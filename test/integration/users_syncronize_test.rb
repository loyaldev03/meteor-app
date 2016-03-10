require 'test_helper'
 
class UsersSyncronizeTest < ActionDispatch::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    Drupal.enable_integration!
    Drupal.test_mode!
    # Pardot.enable_integration! ==> NoMethodError: undefined method `enable_integration!' for Pardot:Module
    # response = '{"id"=>"1810071", "campaign_id"=>"831", "salutation"=>nil, "first_name"=>nil, "last_name"=>nil, "email"=>"cal+sda@ggmail.com", "password"=>nil, "company"=>nil, "website"=>nil, "job_title"=>nil, "department"=>nil, "country"=>nil, "address_one"=>nil, "address_two"=>nil, "city"=>nil, "state"=>nil, "territory"=>nil, "zip"=>nil, "phone"=>nil, "fax"=>nil, "source"=>nil, "annual_revenue"=>nil, "employees"=>nil, "industry"=>nil, "years_in_business"=>nil, "comments"=>nil, "notes"=>nil, "score"=>"0", "grade"=>nil, "last_activity_at"=>nil, "recent_interaction"=>"Never active", "crm_lead_fid"=>nil, "crm_contact_fid"=>nil, "crm_owner_fid"=>nil, "crm_account_fid"=>nil, "crm_opportunity_fid"=>nil, "crm_opportunity_created_at"=>nil, "crm_opportunity_updated_at"=>nil, "crm_opportunity_value"=>nil, "crm_opportunity_status"=>nil, "crm_last_sync"=>nil, "crm_is_sale_won"=>nil, "is_do_not_email"=>nil, "is_do_not_call"=>nil, "opted_out"=>nil, "short_code"=>"fcc52", "is_reviewed"=>nil, "is_starred"=>nil, "created_at"=>"2012-11-13 07:45:46", "updated_at"=>"2012-11-13 07:45:47", "campaign"=>{"id"=>"831", "name"=>"Website Tracking"}, "profile"=>{"id"=>"281", "name"=>"Default", "profile_criteria"=>[{"id"=>"1361", "name"=>"Company Size", "matches"=>"Unknown"}, {"id"=>"1371", "name"=>"Industry", "matches"=>"Unknown"}, {"id"=>"1381", "name"=>"Location", "matches"=>"Unknown"}, {"id"=>"1391", "name"=>"Job Title", "matches"=>"Unknown"}, {"id"=>"1401", "name"=>"Department", "matches"=>"Unknown"}]}, "visitors"=>nil, "visitor_activities"=>nil, "lists"=>nil}'
    # Pardot::Member.any_instance.stubs(:save!).returns(response)

    @admin_agent = Agent.find_by(roles: 'admin') || FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:club_with_api)
    @club_without_api = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_and_api, :club_id => @club.id)
    @terms_of_membership_without_api = FactoryGirl.create(:terms_of_membership_with_gateway_and_api, :club_id => @club_without_api.id)
    
    @club.update_attribute(:name,"club_uno")
    Time.zone = @club.time_zone
    @partner = @club.partner
    @partner.update_attribute(:prefix,"partner_uno")
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    @unsaved_user = FactoryGirl.build(:active_user)
    sign_in_as(@admin_agent)  
  end

  def update_api_id(user, api_id)
    visit show_user_path(:partner_prefix => user.club.partner.prefix, :club_prefix => user.club.name, :user_prefix => user.id)
    assert find_field('input_first_name').value == user.first_name

    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status")do
        click_link_or_button 'Edit'
        fill_in "user[api_id]", :with => api_id
        confirm_ok_js
        click_on 'Update'
    end
  end

  ############################################################
  # TEST
  ############################################################

  # generate stubs related to conn in order to set as nill the api_id
  # test "Allow enter api_id empty when Cancel a member" do
  #   
  #   unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
  #   credit_card = FactoryGirl.build(:credit_card_master_card)
  #   @saved_member = create_member(unsaved_member, credit_card)
  #   @saved_member.update_attribute(:api_id, "1234")
  #   @saved_member.set_as_canceled!
  #   visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
  # end

  test "Syncronize a club - club has a good drupal domain" do
  	assert_not_equal(@club.api_username, nil)
  	assert_not_equal(@club.api_password, nil)
  	assert_not_equal(@club.drupal_domain_id, nil)
  end

  test "Club with invalid 'drupal domain' (that is, a domain where there is no drupal installed)" do
    @club.update_attribute(:drupal_domain_id, 999);
    @saved_user = create_user_by_sloop(@admin_agent, @unsaved_user, nil, nil, @terms_of_membership_with_gateway)
    visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @unsaved_user.first_name

    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status"){	click_link_or_button(I18n.t('buttons.login_remotely_as_user')) }

    assert find_field('input_first_name').value == @unsaved_user.first_name
    within("#sync_status"){ click_link_or_button(I18n.t('buttons.password_reset')) }
    assert find_field('input_first_name').value == @unsaved_user.first_name
    within("#sync_status"){ assert page.has_selector?("#show_remote_data") }
    assert find_field('input_first_name').value == @unsaved_user.first_name

    within("#span_api_id"){ assert page.has_content?("none") }
    within("#td_mi_last_sync_error_at"){ assert page.has_content?("none") }
    within("#td_autologin_url"){ assert page.has_content?("none") }
  end

  test "Club without 'drupal domain'" do
    @saved_user = create_user_by_sloop(@admin_agent, @unsaved_user, nil, nil, @terms_of_membership_without_api)
    visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)

    within(".nav-tabs") do
      page.has_no_selector?("#sync_status")
    end
  end

  # Should not let agent to update api_id when user is 
  # Platform will create Drupal account by Drupal API
  test "Create an user with 'Not synced', 'Synced error' and 'Synced' Status and update it's api id" do
    # @saved_user = create_user_by_sloop(@admin_agent, @unsaved_user, credit_card, nil, @terms_of_membership_with_gateway)
    @saved_user = FactoryGirl.create(:user, club_id: @club.id)
    FactoryGirl.create(:credit_card_master_card, user_id: @saved_user.id)
    membership = FactoryGirl.create(:user_membership, user_id: @saved_user.id, terms_of_membership_id: @terms_of_membership_with_gateway.id)
    @saved_user.update_attribute :current_membership_id, membership.id

    # with not synced status
    visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
    within(".nav-tabs") do
      page.has_selector?("#sync_status_tab")
      click_on("Sync Status")
    end
    within("#span_mi_sync_status"){ page.has_content?('Not Synced') }
    
    # with synced error status
    @saved_user.update_attributes(last_sync_error_at: Time.zone.now, sync_status: 'with_error')
    visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)

    within(".nav-tabs") do
      page.has_selector?("#sync_status")
      click_on("Sync Status")
    end
    within("#span_mi_sync_status"){ page.has_content?('Sync Error') }

    # with synced status
    @saved_user.update_attributes(last_sync_error_at: nil, updated_at: Time.zone.now-1, last_synced_at: Time.zone.now, sync_status: 'synced')
    visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)

    within(".nav-tabs"){ page.has_selector?("#sync_status") }
    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status")do
      assert page.has_selector?("#login_remotely_as_user")
      assert page.has_selector?("#resend_welcome_email")
      assert page.has_selector?("#sync_to_remote")
      assert page.has_selector?("#password_reset")
      assert page.has_selector?("#show_remote_data")
      assert page.has_content?(I18n.t('activerecord.attributes.user.api_id'))
      assert page.has_content?(I18n.t('activerecord.attributes.user.last_synced_at'))
      assert page.has_content?(I18n.t('activerecord.attributes.user.last_sync_error'))
      within("#td_mi_last_synced_at")do
        assert page.has_content?(I18n.l(@saved_user.last_synced_at, :format =>  :dashed) )
      end
      if @saved_user.api_id.present?
        within("#span_api_id"){ assert page.has_content?(@saved_user.api_id.to_s) }
      end
      within("#td_mi_last_sync_error_at"){ assert page.has_content?("none") }

      click_link_or_button 'Edit'
      fill_in "user[api_id]", :with => "1234"
      confirm_ok_js
      click_on 'Update'
    end
    assert page.has_content?("Sync data updated")

    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table") do
      assert page.has_content?("User's api_id changed from nil to \"1234\"")
    end
    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#span_api_id")do
      assert page.has_content?(@saved_user.api_id.to_s)
    end

    # Platform will create Drupal account by Drupal API
    response = '{"uid":"291","name":"test20121029","mail":"test20121029@mailinator.com","theme":"","signature":"","signature_format":"full_html","created":"1351570554","access":"0","login":"0","status":"1","timezone":null,"language":"","picture":null,"init":"test20121029@mailinator.com","data":{"htmlmail_plaintext":0},"roles":{"2":"authenticated user"},"field_profile_address":{"und":[{"value":"reibel","format":null,"safe_value":"reibel"}]},"field_profile_cc_month":{"und":[{"value":"12"}]},"field_profile_cc_number":{"und":[{"value":"XXXX-XXXX-XXXX-8250","format":null,"safe_value":"XXXX-XXXX-XXXX-8250"}]},"field_profile_cc_year":{"und":[{"value":"2012"}]},"field_profile_city":{"und":[{"value":"concepcion","format":null,"safe_value":"concepcion"}]},"field_profile_dob":{"und":[{"value":"1991-10-22T00:00:00","timezone":"UTC","timezone_db":"UTC","date_type":"date"}]},"field_profile_firstname":{"und":[{"value":"name","format":null,"safe_value":"name"}]},"field_profile_gender":{"und":[{"value":"M"}]},"field_profile_lastname":{"und":[{"value":"test","format":null,"safe_value":"test"}]},"field_profile_middle_initial":[],"field_profile_nickname":[],"field_profile_salutation":[],"field_profile_suffix":[],"field_profile_token":[],"field_profile_zip":{"und":[{"value":"12345","format":null,"safe_value":"12345"}]},"field_profile_country":{"und":[{"value":"US","format":null,"safe_value":"US"}]},"field_profile_phone_area_code":{"und":[{"value":"123"}]},"field_profile_phone_country_code":{"und":[{"value":"123"}]},"field_profile_phone_local_number":{"und":[{"value":"1234","format":null,"safe_value":"1234"}]},"field_profile_stateprovince":{"und":[{"value":"KY","format":null,"safe_value":"KY"}]},"field_phoenix_member_id":[],"field_phoenix_member_vid":[],"field_profile_phone_type":{"und":[{"value":"home","format":null,"safe_value":"home"}]},"field_phoenix_pref_example_color":[],"field_phoenix_pref_example_team":[],"rdf_mapping":{"rdftype":["sioc:UserAccount"],"name":{"predicates":["foaf:name"]},"homepage":{"predicates":["foaf:page"],"type":"rel"}}}'
    Drupal::Member.any_instance.stubs(:get).returns(response)
    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status"){ click_link_or_button I18n.t('buttons.show_remote_data') }
    within('#sync-data')do
      assert page.has_content?('"uid":"291"')
      assert page.has_content?('"name":"test20121029"')
      assert page.has_content?('"mail":"test20121029@mailinator.com"')
      assert page.has_content?('"theme":""')
      assert page.has_content?('"signature":""')
      assert page.has_content?('"signature_format":"full_html"')
      assert page.has_content?('"created":"1351570554"')
    end

    # do not allow to use another user's same api_id
    @unsaved_user2 = FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card2 = FactoryGirl.build(:credit_card_american_express)
    @saved_user2 = create_user_by_sloop(@admin_agent, @unsaved_user2, credit_card2, nil, @terms_of_membership_with_gateway)
    @saved_user2.update_attribute(:api_id, "5678")
  
    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status")do
        click_link_or_button 'Edit'
        fill_in "user[api_id]", :with => "5678"
        confirm_ok_js
        click_on 'Update'
    end
    assert page.has_content?("Sync data cannot be updated. Api id already exists")

    # allow api_id empty
    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status")do
        click_link_or_button 'Edit'
        fill_in "user[api_id]", :with => ""
        confirm_ok_js
        click_on 'Update'
    end
    within(".nav-tabs"){ click_on "Operations"}
    within("#operations_table") do
      assert page.has_content?("User's api_id changed from \"1234\" to nil")
    end
    @saved_user.update_attribute(:api_id, "1234")

    # update user's api with invalid information
    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status")do
        click_link_or_button 'Edit'
        fill_in "user[api_id]", :with => "asdr"
        confirm_ok_js
        click_on 'Update'
    end
    page.has_content?('Sync data cannot be updated {:api_id=>["is not a number"]}')

    # unset user's api_id
    within(".nav-tabs"){ click_on("Sync Status") }
    page.has_content?("Sync data updated")
    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status")do
        confirm_ok_js
        click_link_or_button 'Unset'
    end
    page.has_content?("Sync data updated")

    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table"){ page.has_content?("User's api_id changed from \"1234\" to \"\"") }
    within(".nav-tabs"){ click_on("Sync Status") }
    within("#span_api_id"){ assert page.has_content?("none") }

    # Should not let agent to update api_id when user is
    @saved_user.set_as_applied
    visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
    
    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status"){ assert page.has_no_selector?("edit_api_id") }
  end
end