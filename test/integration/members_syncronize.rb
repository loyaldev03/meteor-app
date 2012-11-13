require 'test_helper'
 
class MembersSyncronize < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

 def setup_environment 
    Drupal.enable_integration!
    Pardot.enable_integration!

    response = '{"id"=>"1810071", "campaign_id"=>"831", "salutation"=>nil, "first_name"=>nil, "last_name"=>nil, "email"=>"cal+sda@ggmail.com", "password"=>nil, "company"=>nil, "website"=>nil, "job_title"=>nil, "department"=>nil, "country"=>nil, "address_one"=>nil, "address_two"=>nil, "city"=>nil, "state"=>nil, "territory"=>nil, "zip"=>nil, "phone"=>nil, "fax"=>nil, "source"=>nil, "annual_revenue"=>nil, "employees"=>nil, "industry"=>nil, "years_in_business"=>nil, "comments"=>nil, "notes"=>nil, "score"=>"0", "grade"=>nil, "last_activity_at"=>nil, "recent_interaction"=>"Never active", "crm_lead_fid"=>nil, "crm_contact_fid"=>nil, "crm_owner_fid"=>nil, "crm_account_fid"=>nil, "crm_opportunity_fid"=>nil, "crm_opportunity_created_at"=>nil, "crm_opportunity_updated_at"=>nil, "crm_opportunity_value"=>nil, "crm_opportunity_status"=>nil, "crm_last_sync"=>nil, "crm_is_sale_won"=>nil, "is_do_not_email"=>nil, "is_do_not_call"=>nil, "opted_out"=>nil, "short_code"=>"fcc52", "is_reviewed"=>nil, "is_starred"=>nil, "created_at"=>"2012-11-13 07:45:46", "updated_at"=>"2012-11-13 07:45:47", "campaign"=>{"id"=>"831", "name"=>"Website Tracking"}, "profile"=>{"id"=>"281", "name"=>"Default", "profile_criteria"=>[{"id"=>"1361", "name"=>"Company Size", "matches"=>"Unknown"}, {"id"=>"1371", "name"=>"Industry", "matches"=>"Unknown"}, {"id"=>"1381", "name"=>"Location", "matches"=>"Unknown"}, {"id"=>"1391", "name"=>"Job Title", "matches"=>"Unknown"}, {"id"=>"1401", "name"=>"Department", "matches"=>"Unknown"}]}, "visitors"=>nil, "visitor_activities"=>nil, "lists"=>nil}'
    Pardot::Member.any_instance.stubs(:save!).returns(response)

    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_and_api)
    @club = @terms_of_membership_with_gateway.club
    @club.update_attribute(:name,"club_uno")
    Time.zone = @club.time_zone
    @partner = @club.partner
    @partner.update_attribute(:prefix,"partner_uno")
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    sign_in_as(@admin_agent)
   end

	def fill_in_member(unsaved_member, credit_card, tom)
    club = tom.club
    visit members_path(:partner_prefix => club.partner.prefix, :club_prefix => club.name)
    wait_until{ click_link_or_button 'New Member' }

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select(unsaved_member.gender, :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        fill_in 'member[state]', :with => unsaved_member.state
        select(unsaved_member.country_name, :from => 'member[country]')
        fill_in 'member[city]', :with => unsaved_member.city
        fill_in 'member[last_name]', :with => unsaved_member.last_name
        fill_in 'member[zip]', :with => unsaved_member.zip
      }
    end
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
        fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
        fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
        select(unsaved_member.type_of_phone_number.capitalize, :from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'  	
  end


  ############################################################
  # TEST
  ############################################################

  test "Syncronize a club - club has a good drupal domain" do
    setup_environment 
  	wait_until{ assert_not_equal(@club.api_username, nil) }
  	wait_until{ assert_not_equal(@club.api_password, nil) }
  	wait_until{ assert_not_equal(@club.drupal_domain_id, nil) }
  end

  test "Club with invalid 'drupal domain' ( that is, a domain where there is no drupal installed)" do
  	setup_environment 
    @club.update_attribute(:drupal_domain_id, 999);
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)

    fill_in_member(unsaved_member,credit_card,@terms_of_membership_with_gateway)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)

    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#sync_status")do
      wait_until{
      	click_link_or_button(I18n.t('buttons.login_remotely_as_member'))
      }
    end
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    within("#sync_status")do
      wait_until{
        click_link_or_button(I18n.t('buttons.password_reset'))
      }
    end
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    within("#sync_status")do
      wait_until{
        assert page.has_selector?("#show_remote_data")
      }
    end
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within("#span_api_id"){
      wait_until{ assert page.has_content?("none") }
    }
    within("#td_mi_last_sync_error_at"){
      wait_until{ assert page.has_content?("none") }
    }
    within("#td_autologin_url"){
      wait_until{ assert page.has_content?("none") }
    }
  end

  test "Search members by Indifferent Sync Status " do
    setup_environment 
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card,@terms_of_membership_with_gateway)
    visit members_path(:partner_prefix => @terms_of_membership_with_gateway.club.partner.prefix, :club_prefix => @terms_of_membership_with_gateway.club.name)

    fill_in("member[last_name]", :with => unsaved_member.last_name)
    select("Indifferent", :from => 'member[sync_status]')
    @saved_member = Member.find_by_email(unsaved_member.email)
    click_link_or_button 'Search'

    within("#members")do
      wait_until{ assert page.has_content?(@saved_member.visible_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.external_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.full_name) }
    end
  end

  test "Search members by Not Synced Sync Status " do
    setup_environment 
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card, @terms_of_membership_with_gateway)
    visit members_path(:partner_prefix => @terms_of_membership_with_gateway.club.partner.prefix, :club_prefix => @terms_of_membership_with_gateway.club.name)

    fill_in("member[last_name]", :with => unsaved_member.last_name)
    select("Not Synced", :from => 'member[sync_status]')
    @saved_member = Member.find_by_email(unsaved_member.email)
    click_link_or_button 'Search'

    within("#members")do
      wait_until{ assert page.has_content?(@saved_member.visible_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.external_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.full_name) }
    end
  end

  test "Club without 'drupal domain'" do
    setup_environment 
    @terms_of_membership_with_gateway2 = FactoryGirl.create(:terms_of_membership_with_gateway)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @terms_of_membership_with_gateway2.club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member, credit_card, @terms_of_membership_with_gateway2)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)

    within(".nav-tabs") do
      wait_until { page.has_no_selector?("#sync_status_tab") }
    end
  end

  test "Search members by Synced Sync Status" do
    setup_environment 
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card,@terms_of_membership_with_gateway)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    wait_until { assert page.has_content?("Search") }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)

    fill_in("member[last_name]", :with => unsaved_member.last_name)
    select("Synced", :from => 'member[sync_status]')

    click_link_or_button 'Search'

    within("#members")do
      wait_until{ assert page.has_content?(@saved_member.visible_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.external_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.full_name) }
    end
  end

  test "Search members by Without Error Sync Status " do
    setup_environment 
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)

    fill_in_member(unsaved_member,credit_card,@terms_of_membership_with_gateway)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    wait_until { assert page.has_content?("Search") }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)

    fill_in("member[last_name]", :with => unsaved_member.last_name)
    select("Without Error", :from => 'member[sync_status]')
    click_link_or_button 'Search'

    within("#members")do
      wait_until{ assert page.has_content?(@saved_member.visible_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.external_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.full_name) }
    end
  end

  test "Search members by With Error Sync Status " do
    setup_environment 
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)

    fill_in_member(unsaved_member,credit_card,@terms_of_membership_with_gateway)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    wait_until { assert page.has_content?("Search") }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:last_sync_error_at, Time.zone.now)

    fill_in("member[last_name]", :with => unsaved_member.last_name)
    select("With Error", :from => 'member[sync_status]')
    click_link_or_button 'Search'

    within("#members")do
      wait_until{ assert page.has_content?(@saved_member.visible_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.external_id.to_s) }
      wait_until{ assert page.has_content?(@saved_member.full_name) }
    end
  end

  test "Sync Status tab" do
    setup_environment 
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    fill_in_member(unsaved_member,credit_card,@terms_of_membership_with_gateway)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)
     visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#sync_status")do
      wait_until{
        assert page.has_selector?("#login_remotely_as_member")
        assert page.has_selector?("#resend_welcome_email")
        assert page.has_selector?("#sync_to_remote")
        assert page.has_selector?("#password_reset")
        assert page.has_selector?("#show_remote_data")
        assert page.has_content?(I18n.t('activerecord.attributes.member.api_id'))
        assert page.has_content?(I18n.t('activerecord.attributes.member.last_synced_at'))
        assert page.has_content?(I18n.t('activerecord.attributes.member.last_sync_error'))
      }
    end
    within("#td_mi_last_synced_at")do
      assert page.has_content?(I18n.l(@saved_member.last_synced_at, :format =>  :dashed) )
    end
    if @saved_member.api_id.present?
      within("#span_api_id"){ wait_until{ assert page.has_content?(@saved_member.api_id.to_s) } }
    end
    within("#td_mi_last_sync_error_at"){ wait_until{ assert page.has_content?("none") } }
  end

  test "Update member's api_id (Remote ID)" do
    setup_environment
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    fill_in_member(unsaved_member,credit_card,@terms_of_membership_with_gateway)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)
    
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#sync_status")do
      wait_until{
        click_link_or_button 'Edit'
        fill_in "member[api_id]", :with => "1234"
        confirm_ok_js
        click_on 'Update'
      }
    end
    wait_until{ page.has_content?("Sync data updated") }

    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table"){
      wait_until{ page.has_content?("Member's api_id changed from nil to \"1234\"") }
    }

    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#span_api_id")do
      wait_until { assert page.has_content?(@saved_member.api_id.to_s) }
    end
  end

  test "Unset member's api_id (Remote ID)" do
    setup_environment
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    fill_in_member(unsaved_member,credit_card,@terms_of_membership_with_gateway)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#sync_status")do
      wait_until{
        click_link_or_button 'Edit'
        fill_in "member[api_id]", :with => "1234"
        confirm_ok_js
        click_on 'Update'
      }
    end
    wait_until{ page.has_content?("Sync data updated") }

    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#sync_status")do
      wait_until{
        confirm_ok_js
        click_link_or_button 'Unset'
      }
    end
    wait_until{ page.has_content?("Sync data updated") }

    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table"){
      wait_until{ page.has_content?("Member's api_id changed from \"1234\" to \"\"") }
    }
    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#span_api_id")do
      wait_until { assert page.has_content?("none") }
    end
  end

  test "Create a member with Synced Status" do
    setup_environment
    unsaved_member =  FactoryGirl.build(:member_with_api, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info  = FactoryGirl.build(:complete_enrollment_info_with_amount)
    
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)

     visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within(".nav-tabs") do
      wait_until { page.has_selector?("#sync_status_tab") }
    end
  end

  test "Create a member with Not Synced status" do
    setup_environment
    unsaved_member =  FactoryGirl.build(:member_with_api, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info  = FactoryGirl.build(:complete_enrollment_info_with_amount)

    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)

    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within(".nav-tabs") do
      wait_until { page.has_selector?("#sync_status_tab") }
      click_on("Sync Status")
    end
    within("#span_mi_sync_status")do
      wait_until{ page.has_content?('Not Synced') }
    end
  end

  test "Create a member with Sync Error status" do
    setup_environment
    unsaved_member =  FactoryGirl.build(:member_with_api, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info  = FactoryGirl.build(:complete_enrollment_info_with_amount)

    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:last_sync_error_at, Time.zone.now)
    
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within(".nav-tabs") do
      wait_until { page.has_selector?("#sync_status_tab") }
      click_on("Sync Status")
    end
    within("#span_mi_sync_status")do
      wait_until{ page.has_content?('Sync Error') }
    end
  end

  test "Platform will create Drupal account by Drupal API" do
    setup_environment
    response = '{"uid":"291","name":"test20121029","mail":"test20121029@mailinator.com","theme":"","signature":"","signature_format":"full_html","created":"1351570554","access":"0","login":"0","status":"1","timezone":null,"language":"","picture":null,"init":"test20121029@mailinator.com","data":{"htmlmail_plaintext":0},"roles":{"2":"authenticated user"},"field_profile_address":{"und":[{"value":"reibel","format":null,"safe_value":"reibel"}]},"field_profile_cc_month":{"und":[{"value":"12"}]},"field_profile_cc_number":{"und":[{"value":"XXXX-XXXX-XXXX-8250","format":null,"safe_value":"XXXX-XXXX-XXXX-8250"}]},"field_profile_cc_year":{"und":[{"value":"2012"}]},"field_profile_city":{"und":[{"value":"concepcion","format":null,"safe_value":"concepcion"}]},"field_profile_dob":{"und":[{"value":"1991-10-22T00:00:00","timezone":"UTC","timezone_db":"UTC","date_type":"date"}]},"field_profile_firstname":{"und":[{"value":"name","format":null,"safe_value":"name"}]},"field_profile_gender":{"und":[{"value":"M"}]},"field_profile_lastname":{"und":[{"value":"test","format":null,"safe_value":"test"}]},"field_profile_middle_initial":[],"field_profile_nickname":[],"field_profile_salutation":[],"field_profile_suffix":[],"field_profile_token":[],"field_profile_zip":{"und":[{"value":"12345","format":null,"safe_value":"12345"}]},"field_profile_country":{"und":[{"value":"US","format":null,"safe_value":"US"}]},"field_profile_phone_area_code":{"und":[{"value":"123"}]},"field_profile_phone_country_code":{"und":[{"value":"123"}]},"field_profile_phone_local_number":{"und":[{"value":"1234","format":null,"safe_value":"1234"}]},"field_profile_stateprovince":{"und":[{"value":"KY","format":null,"safe_value":"KY"}]},"field_phoenix_member_uuid":[],"field_phoenix_member_vid":[],"field_profile_phone_type":{"und":[{"value":"home","format":null,"safe_value":"home"}]},"field_phoenix_pref_example_color":[],"field_phoenix_pref_example_team":[],"rdf_mapping":{"rdftype":["sioc:UserAccount"],"name":{"predicates":["foaf:name"]},"homepage":{"predicates":["foaf:page"],"type":"rel"}}}'
    Drupal::Member.any_instance.stubs(:get).returns(response)
    unsaved_member =  FactoryGirl.build(:member_with_api, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info  = FactoryGirl.build(:complete_enrollment_info_with_amount)

    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:last_sync_error_at, Time.zone.now)
    
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    
    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#span_mi_sync_status")do
      wait_until{
        page.has_content?('Sync Error') 
      }
    end
    within("#sync_status")do
      wait_until{
        click_link_or_button 'Edit'
        fill_in "member[api_id]", :with => "1234"
        confirm_ok_js
        click_on 'Update'
      }
    end
    wait_until{ page.has_content?("Sync data updated") }
    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#sync_status")do
      click_link_or_button I18n.t('buttons.show_remote_data')
    end

    within('#sync-data')do
      wait_until{ assert page.has_content?('"uid":"291"') }
      wait_until{ assert page.has_content?('"name":"test20121029"') }
      wait_until{ assert page.has_content?('"mail":"test20121029@mailinator.com"') }
      wait_until{ assert page.has_content?('"theme":""') }
      wait_until{ assert page.has_content?('"signature":""') }
      wait_until{ assert page.has_content?('"signature_format":"full_html"') }
      wait_until{ assert page.has_content?('"created":"1351570554"') }
    end
  end
end

