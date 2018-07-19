require 'test_helper'
 
class UsersSyncronizeTest < ActionDispatch::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  def setup_user(with_api = true)
    Drupal.enable_integration!
    Drupal.test_mode!

    @admin_agent = Agent.find_by(roles: 'admin') || FactoryBot.create(:confirmed_admin_agent)
    @club = FactoryBot.create(:club_with_api)
    @club_without_api = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway_and_api = FactoryBot.create(:terms_of_membership_with_gateway_and_api, :club_id => @club.id)
    @terms_of_membership_without_api = FactoryBot.create(:terms_of_membership_with_gateway_and_api, :club_id => @club_without_api.id)
    
    Time.zone = @club.time_zone
    @partner = @club.partner
    @disposition_type = FactoryBot.create(:disposition_type, :club_id => @club.id)
    @unsaved_user = FactoryBot.build(:active_user)

    if with_api
      body = { uid: 43655, uri: 'https://test/api/user/43655', urllogin: { token: 'PWWDuGc-elRE', url: 'https://test/l/PWWDuGc-elRE' } }
      Faraday::Connection.any_instance.stubs(:post).returns(Hashie::Mash.new({ status: 200, body: {uid: 43655, uri: 'https://test/api/user/43655', urllogin: {token: 'PWWDuGc-elRE', url: 'https://test/l/PWWDuGc-elRE'}} }))
      @saved_user = create_user_by_sloop(@admin_agent, @unsaved_user, nil, nil, @terms_of_membership_with_gateway_and_api)
    else
      @saved_user = create_user_by_sloop(@admin_agent, @unsaved_user, nil, nil, @terms_of_membership_without_api)
    end
    sign_in_as(@admin_agent)  
  end

  def update_api_id(user, api_id)
    visit show_user_path(:partner_prefix => user.club.partner.prefix, :club_prefix => user.club.name, :user_prefix => user.id)
    assert find_field('input_first_name').value == user.first_name

    within(".nav-tabs"){ click_on("Sync Status") }
    within("#sync_status")do
        click_link_or_button 'Edit'
        fill_in "user[api_id]", :with => api_id
        click_on 'Update'
        confirm_ok_js
    end
  end

  # ############################################################
  # # TEST
  # ############################################################

  # # generate stubs related to conn in order to set as nill the api_id
  # test "Allow enter api_id empty when Cancel a member" do
  #   unsaved_member = FactoryBot.build(:active_member, :club_id => @club.id)
  #   credit_card = FactoryBot.build(:credit_card_master_card)
  #   @saved_member = create_member(unsaved_member, credit_card)
  #   @saved_member.update_attribute(:api_id, "1234")
  #   @saved_member.set_as_canceled!
  #   visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
  # end

  # TODO: Fix this test. It is not working on Jenkins
  # test "Club without 'drupal domain'" do
  #   setup_user(false)
  #   visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)

  #   within(".nav-tabs") do
  #     page.has_no_selector?("#sync_status")
  #   end
  # end

  # TODO: Fix this test. It is not working on Jenkins
  # Should not let agent to update api_id when user is 
  # test "Create an user with 'Not synced', 'Synced error' and 'Synced' Status and update it's api id" do
  #   setup_user

  #   # with not synced status
  #   visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
  #   within(".nav-tabs") do
  #     page.has_selector?("#sync_status_tab")
  #     click_on("Sync Status")
  #   end
  #   within("#span_mi_sync_status"){ page.has_content?('Not Synced') }
    
  #   # with synced error status
  #   @saved_user.update_attributes(last_sync_error_at: Time.zone.now, sync_status: 'with_error')
  #   visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)

  #   within(".nav-tabs") do
  #     page.has_selector?("#sync_status")
  #     click_on("Sync Status")
  #   end
  #   within("#span_mi_sync_status"){ page.has_content?('Sync Error') }

  #   # with synced status
  #   @saved_user.update_attributes(last_sync_error_at: nil, updated_at: Time.zone.now-1, last_synced_at: Time.zone.now, sync_status: 'synced')
  #   visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)

  #   within(".nav-tabs"){ page.has_selector?("#sync_status") }
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   within("#sync_status")do
  #     assert page.has_selector?("#login_remotely_as_user")
  #     assert page.has_selector?("#resend_welcome_email")
  #     assert page.has_selector?("#sync_to_remote")
  #     assert page.has_selector?("#password_reset")
  #     assert page.has_selector?("#show_remote_data")
  #     assert page.has_content?(I18n.t('activerecord.attributes.user.api_id'))
  #     assert page.has_content?(I18n.t('activerecord.attributes.user.last_synced_at'))
  #     assert page.has_content?(I18n.t('activerecord.attributes.user.last_sync_error'))
  #     within("#td_mi_last_synced_at")do
  #       assert page.has_content?(I18n.l(@saved_user.last_synced_at, :format =>  :dashed) )
  #     end
  #     if @saved_user.api_id.present?
  #       within("#span_api_id"){ assert page.has_content?(@saved_user.api_id.to_s) }
  #     end
  #     within("#td_mi_last_sync_error_at"){ assert page.has_content?("none") }

  #     click_link_or_button 'Edit'
  #     fill_in "user[api_id]", :with => "1234"
  #     click_on 'Update'
  #     confirm_ok_js
  #   end
  #   assert page.has_content?("Sync data updated")

  #   within(".nav-tabs") do
  #     click_on("Operations")
  #   end
  #   within("#operations_table") do
  #     assert page.has_content?("User's api_id changed from \"43655\" to \"1234\"")
  #   end
  #   within(".nav-tabs") do
  #     click_on("Sync Status")
  #   end
  #   within("#span_api_id")do
  #       @saved_user.reload
  #     assert page.has_content?(@saved_user.api_id.to_s)
  #   end

  #   # do not allow to use another user's same api_id
  #   @unsaved_user2 = FactoryBot.build(:active_user, :club_id => @club.id)
  #   credit_card2 = FactoryBot.build(:credit_card_american_express)
  #   @saved_user2 = create_user_by_sloop(@admin_agent, @unsaved_user2, credit_card2, nil, @terms_of_membership_with_gateway_and_api)
  #   @saved_user2.update_attribute(:api_id, "5678")
  
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   within("#sync_status")do
  #       click_link_or_button 'Edit'
  #       fill_in "user[api_id]", :with => "5678"
  #       click_on 'Update'
  #       confirm_ok_js
  #   end
  #   assert page.has_content?("Sync data cannot be updated. Api id already exists")

  #   # allow api_id empty
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   within("#sync_status")do
  #       click_link_or_button 'Edit'
  #       fill_in "user[api_id]", :with => ""
  #       click_on 'Update'
  #       confirm_ok_js
  #   end
  #   within(".nav-tabs"){ click_on "Operations"}
  #   within("#operations_table") do
  #     assert page.has_content?("User's api_id changed from \"1234\" to nil")
  #   end
  #   @saved_user.update_attribute(:api_id, "1234")

  #   # update user's api with invalid information
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   within("#sync_status")do
  #       click_link_or_button 'Edit'
  #       fill_in "user[api_id]", :with => "asdr"
  #       click_on 'Update'
  #       confirm_ok_js
  #   end
  #   page.has_content?('Sync data cannot be updated {:api_id=>["is not a number"]}')

  #   # unset user's api_id
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   page.has_content?("Sync data updated")
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   within("#sync_status")do
  #       click_link_or_button 'Unset'
  #       confirm_ok_js
  #   end
  #   page.has_content?("Sync data updated")

  #   within(".nav-tabs"){ click_on("Operations") }
  #   within("#operations_table"){ page.has_content?("User's api_id changed from \"1234\" to \"\"") }
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   within("#span_api_id"){ assert page.has_content?("none") }
  # end

  # TODO: Fix this test. It is not working on Jenkins
  # test 'Platform will create Drupal account by Drupal API' do
  #   setup_user
  #   @saved_user.update_attribute(:api_id, "1234")
    
  #   visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
  #   response = '{"uid":"291","name":"test20121029","mail":"test20121029@mailinator.com","theme":"","signature":"","signature_format":"full_html","created":"1351570554","access":"0","login":"0","status":"1","timezone":null,"language":"","picture":null,"init":"test20121029@mailinator.com","data":{"htmlmail_plaintext":0},"roles":{"2":"authenticated user"},"field_profile_address":{"und":[{"value":"reibel","format":null,"safe_value":"reibel"}]},"field_profile_cc_month":{"und":[{"value":"12"}]},"field_profile_cc_number":{"und":[{"value":"XXXX-XXXX-XXXX-8250","format":null,"safe_value":"XXXX-XXXX-XXXX-8250"}]},"field_profile_cc_year":{"und":[{"value":"2012"}]},"field_profile_city":{"und":[{"value":"concepcion","format":null,"safe_value":"concepcion"}]},"field_profile_dob":{"und":[{"value":"1991-10-22T00:00:00","timezone":"UTC","timezone_db":"UTC","date_type":"date"}]},"field_profile_firstname":{"und":[{"value":"name","format":null,"safe_value":"name"}]},"field_profile_gender":{"und":[{"value":"M"}]},"field_profile_lastname":{"und":[{"value":"test","format":null,"safe_value":"test"}]},"field_profile_middle_initial":[],"field_profile_nickname":[],"field_profile_salutation":[],"field_profile_suffix":[],"field_profile_token":[],"field_profile_zip":{"und":[{"value":"12345","format":null,"safe_value":"12345"}]},"field_profile_country":{"und":[{"value":"US","format":null,"safe_value":"US"}]},"field_profile_phone_area_code":{"und":[{"value":"123"}]},"field_profile_phone_country_code":{"und":[{"value":"123"}]},"field_profile_phone_local_number":{"und":[{"value":"1234","format":null,"safe_value":"1234"}]},"field_profile_stateprovince":{"und":[{"value":"KY","format":null,"safe_value":"KY"}]},"field_phoenix_member_id":[],"field_phoenix_member_vid":[],"field_profile_phone_type":{"und":[{"value":"home","format":null,"safe_value":"home"}]},"field_phoenix_pref_example_color":[],"field_phoenix_pref_example_team":[],"rdf_mapping":{"rdftype":["sioc:UserAccount"],"name":{"predicates":["foaf:name"]},"homepage":{"predicates":["foaf:page"],"type":"rel"}}}'
  #   Drupal::Member.any_instance.stubs(:get).returns(response)

  #   visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   within("#sync_status"){ click_link_or_button I18n.t('buttons.show_remote_data') }
  #   within('#sync-data')do
  #     assert page.has_content?('"uid":"291"')
  #     assert page.has_content?('"name":"test20121029"')
  #     assert page.has_content?('"mail":"test20121029@mailinator.com"')
  #     assert page.has_content?('"theme":""')
  #     assert page.has_content?('"signature":""')
  #     assert page.has_content?('"signature_format":"full_html"')
  #     assert page.has_content?('"created":"1351570554"')
  #   end
  # end

  # TODO: Fix this test. It is not working on Jenkins
  # test 'Should not let agent to update api_id when user is applied' do
  #   setup_user
  #   approval_tom = FactoryBot.create(:terms_of_membership_with_gateway_and_api, :club_id => @club.id, needs_enrollment_approval: true)
  #   @saved_user = create_user_by_sloop(@admin_agent, @unsaved_user, nil, nil, approval_tom)
  #   visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
    
  #   within(".nav-tabs"){ click_on("Sync Status") }
  #   within("#sync_status"){ assert page.has_no_selector?("edit_api_id") }
  # end
end