require 'test_helper'
 
class MembersSyncronize < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

 def setup

    Drupal.enable_integration!

    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_and_api)
    @club = @terms_of_membership_with_gateway.club
    Time.zone = @club.time_zone
    @partner = @club.partner
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    sign_in_as(@admin_agent)
   end

	def fill_in_member(unsaved_member, credit_card)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
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
  	wait_until{ assert_not_equal(@club.api_username, nil) }
  	wait_until{ assert_not_equal(@club.api_password, nil) }
  	wait_until{ assert_not_equal(@club.drupal_domain_id, nil) }
  end

  test "Club with invalid 'drupal domain' ( that is, a domain where there is no drupal installed)" do
  	@club.update_attribute(:drupal_domain_id, 999);
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)

    within(".nav-tabs") do
      click_on("Sync Status")
    end
    within("#sync_status")do
      wait_until{
      	click_link_or_button('Login Remotely as Member')
      }
    end
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    within("#sync_status")do
      wait_until{
        click_link_or_button('Password Reset')
      }
    end
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    # within("#sync_status")do
    #   wait_until{
    #     click_link_or_button('Show Remote Data')
    #   }
    # end
    # wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within("#span_api_id"){
      wait_until{ assert page.has_content?("none") }
    }
    within("#td_las_sync_error"){
      wait_until{ assert page.has_content?("none") }
    }
    within("#td_autologin_url"){
      wait_until{ assert page.has_content?("none") }
    }
  end

  test "Search members by Indifferent Sync Status " do
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

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
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

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
    @terms_of_membership_with_gateway2 = FactoryGirl.create(:terms_of_membership_with_gateway)
    @club2 = @terms_of_membership_with_gateway2.club
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)

    within(".nav-tabs") do
      wait_until { page.has_no_selector?(:xpath, '//a[@id="sync_status"]') }
    end
  end

  test "Search members by Synced Sync Status" do
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card)
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
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)

    fill_in_member(unsaved_member,credit_card)
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
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)

    fill_in_member(unsaved_member,credit_card)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    wait_until { assert page.has_content?("Search") }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:last_sync_error_at, Time.zone.now)

    puts @saved_member.last_sync_error_at

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
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    fill_in_member(unsaved_member,credit_card)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    fill_in_member(unsaved_member,credit_card)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    fill_in_member(unsaved_member,credit_card)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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

  test "Unset member's api_id (Remote ID)" do
    unsaved_member =  FactoryGirl.build(:member_with_api, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info  = FactoryGirl.build(:complete_enrollment_info_with_amount)
    
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:updated_at, Time.zone.now-1)
    @saved_member.update_attribute(:last_synced_at, Time.zone.now)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within(".nav-tabs") do
      wait_until { page.has_selector?(:xpath, '//a[@id="sync_status"]') }
    end
  end

  # test "Create a member with Not Synced status" do
  #   unsaved_member =  FactoryGirl.build(:member_with_api, :club_id => @club.id)
  #   credit_card = FactoryGirl.build(:credit_card_master_card)
  #   enrollment_info  = FactoryGirl.build(:complete_enrollment_info_with_amount)

  #   create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
  #   @saved_member = Member.find_by_email(unsaved_member.email)
  #   @saved_member.update_attribute(:updated_at, Time.zone.now-1)
  #   @saved_member.update_attribute(:last_synced_at, Time.zone.now)

  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  #   wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

  #   within(".nav-tabs") do
  #     wait_until { page.has_selector?(:xpath, '//a[@id="sync_status"]') }
  #     click_on("Sync Status")
  #   end
  #   within("#span_mi_sync_status")do
  #     wait_until{ page.has_content?('Not Synced') }
  #   end
  # end

end