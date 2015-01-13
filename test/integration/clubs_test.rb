require 'test_helper' 
 
class ClubTest < ActionController::IntegrationTest
 
  setup do
    @partner = FactoryGirl.create(:partner)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end


  ###########################################################
  # TESTS
  ###########################################################

  def configure_exact_target(et_username, et_password, et_business_unit, et_prospect_list, et_members_list, club_id_for_test, et_endpoint)
    select 'Exact Target', :from => 'club[marketing_tool_client]'
    fill_in 'marketing_tool_attributes[et_username]', with: et_username
    fill_in 'marketing_tool_attributes[et_password]', with: et_password
    fill_in 'marketing_tool_attributes[et_business_unit]', with: et_business_unit
    fill_in 'marketing_tool_attributes[et_prospect_list]', with: et_prospect_list
    fill_in 'marketing_tool_attributes[et_members_list]', with: et_members_list
    fill_in 'marketing_tool_attributes[club_id_for_test]', with: club_id_for_test
    fill_in 'marketing_tool_attributes[et_endpoint]', with: et_endpoint
  end

  def configure_mailchimp_mandrill(mailchimp_api_key, mandrill_api_key, mailchimp_list_id)
    select 'Mailchimp/Mandrill', :from => 'club[marketing_tool_client]'
    fill_in 'marketing_tool_attributes[mandrill_api_key]', with: mandrill_api_key
    fill_in 'marketing_tool_attributes[mailchimp_api_key]', with: mailchimp_api_key
    fill_in 'marketing_tool_attributes[mailchimp_list_id]', with: mailchimp_list_id
  end

  test "create club" do
    unsaved_club = FactoryGirl.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[api_username]', :with => unsaved_club.api_username
    fill_in 'club[api_password]', :with => unsaved_club.api_password
    fill_in 'club[cs_phone_number]', :with => unsaved_club.cs_phone_number
    attach_file('club[logo]', "#{Rails.root}/test/integration/test_img.png")
    check('club[requires_external_id]')
    select('application', :from => 'club[theme]')
    assert_difference('Club.count', 1) do
      click_link_or_button 'Create Club'
      assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    end
  end

  test "Search option in My Clubs should not affect front end perfomance" do
    saved_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    visit my_clubs_path
    within("#my_clubs_table_filter") do
      find(:css, "input").set(saved_club.name)
    end
    within("#my_clubs_table") do
      page.has_content?(saved_club.name)
    end
  end

  test "create blank club" do
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    click_link_or_button 'Create Club'
    assert page.has_content?("can't be blank")
  end

  test "should read club" do
    saved_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    visit clubs_path(@partner.prefix)
    within("#clubs_table") do
      assert page.has_content?(saved_club.id.to_s)
      assert page.has_content?(saved_club.name)
      assert page.has_content?(saved_club.description)
    end

    visit my_clubs_path
    within("#my_clubs_table") do
      assert page.has_content?(saved_club.id.to_s)
      assert page.has_content?(saved_club.name)
      assert page.has_content?(saved_club.description)
    end
  end

  test "should update club" do
    saved_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    visit clubs_path(@partner.prefix)
    within("#clubs_table") do
      click_link_or_button 'Edit'
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
    assert_equal(saved_club.reload.api_username, 'another api username')
    assert_equal(saved_club.reload.api_password, 'another api password')
    assert_equal(saved_club.reload.description, 'new description')
  end

  test "should delete club" do
    saved_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    visit clubs_path(@partner.prefix)
    confirm_ok_js
    within("#clubs_table") do
      click_link_or_button 'Destroy'
    end
    assert page.has_content?("Club #{saved_club.name} was successfully destroyed")
    assert Club.with_deleted.where(:id => saved_club.id).first
  end

  test "should create default product when creating club" do
    unsaved_club = FactoryGirl.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[api_username]', :with => unsaved_club.api_username
    fill_in 'club[api_password]', :with => unsaved_club.api_password
    fill_in 'club[cs_phone_number]', :with => unsaved_club.cs_phone_number
    attach_file('club[logo]', "#{Rails.root}/test/integration/test_img.png")
    check('club[requires_external_id]')
    select('application', :from => 'club[theme]')
    assert_difference('Club.count') do
      click_link_or_button 'Create Club'
    end
    assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    click_link_or_button 'Back'
    within("#clubs_table") do
      click_link_or_button 'Products'
    end
    within("#products_table") do
      Club::DEFAULT_PRODUCT.each do |sku|
        assert page.has_content?(sku)
      end
    end
  end

  test "should see all clubs as admin on my clubs section" do
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }
    within(".navbar"){ click_link_or_button("My Clubs") }
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?("Show")
      assert page.has_content?("Edit")
      assert page.has_content?("Users")
      assert page.has_content?("Products")
      assert page.has_content?("Fulfillments")
    end
  end

  test "Add a contact number by club" do
    @club = FactoryGirl.create(:simple_club_with_gateway, :name => "new_club", :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    
    unsaved_blacklisted_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_blacklisted_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @blacklisted_user = User.find_by_email(unsaved_blacklisted_user.email)
    @blacklisted_user.blacklist(@admin_agent,"Testing")

    
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    fill_in_user(unsaved_user, credit_card)

    assert page.has_content?("There was an error with your credit card information. Please call member services at: #{@club.cs_phone_number}.")
    assert page.has_content?("number: Credit card is blacklisted")
  end

  test "Display a club without PGC" do
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    @club.payment_gateway_configurations.first.update_attribute(:club_id,nil)
    visit my_clubs_path
    click_link_or_button 'users'
    assert page.has_no_content?("We're sorry, but something went wrong.")
  end

  test "Configure and Update ET marketing gateway - Login by General Admin" do
    unsaved_club = FactoryGirl.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[cs_phone_number]', :with => unsaved_club.cs_phone_number

    configure_exact_target("et_username_test","et_password_test","et_business_unit_test", "et_prospect_list_test", "et_members_list_test", "club_id_for_test", "et_endpoint")

    assert_difference('Club.count', 1) do
      click_link_or_button 'Create Club'
      assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    end
    assert page.has_content? "et_username_test"
    assert page.has_content? "et_password_test"
    assert page.has_content? "et_business_unit_test"
    assert page.has_content? "et_prospect_list_test"
    assert page.has_content? "et_members_list_test"
    assert page.has_content? "club_id_for_test"
    assert page.has_content? "et_endpoint"

    club = Club.last
    assert club.exact_target_client?
    click_link_or_button('Edit')

    configure_exact_target("et_username_test_new","et_password_test_new","et_business_unit_test_new", "et_prospect_list_test_new", "et_members_list_test_new", "club_id_for_test_new", "et_endpoint_new")
    click_link_or_button 'Update Club'

    assert page.has_content? "et_username_test_new"
    assert page.has_content? "et_password_test_new"
    assert page.has_content? "et_business_unit_test_new"
    assert page.has_content? "et_prospect_list_test_new"
    assert page.has_content? "et_members_list_test_new"
    assert page.has_content? "club_id_for_test_new"
    assert page.has_content? "et_endpoint_new"    
  end

  test "Configure and Update Mailchimp/Mandrill marketing gateway - Login by General Admin" do
    unsaved_club = FactoryGirl.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[cs_phone_number]', :with => unsaved_club.cs_phone_number

    configure_mailchimp_mandrill("mailchimp_api_key_test","mandrill_api_key_test","list_id_test")

    assert_difference('Club.count', 1) do
      click_link_or_button 'Create Club'
      assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    end
    assert page.has_content? "mailchimp_api_key_test"
    assert page.has_content? "mandrill_api_key_test"
    assert page.has_content? "list_id_test"

    club = Club.last
    assert club.mailchimp_mandrill_client?
    click_link_or_button('Edit')
    
    configure_mailchimp_mandrill("mailchimp_api_key_test_new","mandrill_api_key_test_new","list_id_test_new")
    click_link_or_button 'Update Club'
  end

  test "Configure and Update ET marketing gateway - Login by Admin by Club" do
    unsaved_club = FactoryGirl.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[cs_phone_number]', :with => unsaved_club.cs_phone_number

    configure_exact_target("et_username_test","et_password_test","et_business_unit_test", "et_prospect_list_test", "et_members_list_test", "club_id_for_test", "et_endpoint")

    assert_difference('Club.count', 1) do
      click_link_or_button 'Create Club'
      assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    end
    assert page.has_content? "et_username_test"
    assert page.has_content? "et_password_test"
    assert page.has_content? "et_business_unit_test"
    assert page.has_content? "et_prospect_list_test"
    assert page.has_content? "et_members_list_test"
    assert page.has_content? "club_id_for_test"
    assert page.has_content? "et_endpoint"

    club = Club.last
    assert club.exact_target_client?

    @admin_agent.update_attribute :roles, ''
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @admin_agent.id
    club_role.role = 'admin'
    club_role.save

    click_link_or_button('Edit')
    configure_exact_target("et_username_test_new","et_password_test_new","et_business_unit_test_new", "et_prospect_list_test_new", "et_members_list_test_new", "club_id_for_test_new", "et_endpoint_new")
    click_link_or_button 'Update Club'

    assert page.has_content? "et_username_test_new"
    assert page.has_content? "et_password_test_new"
    assert page.has_content? "et_business_unit_test_new"
    assert page.has_content? "et_prospect_list_test_new"
    assert page.has_content? "et_members_list_test_new"
    assert page.has_content? "club_id_for_test_new"
    assert page.has_content? "et_endpoint_new"

  end

  test "Configure and Update Mailchimp/Mandrill marketing gateway - Login by Admin by Club" do
    unsaved_club = FactoryGirl.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in 'club[name]', :with => unsaved_club.name
    fill_in 'club[description]', :with => unsaved_club.description
    fill_in 'club[cs_phone_number]', :with => unsaved_club.cs_phone_number

    configure_mailchimp_mandrill("mailchimp_api_key_test","mandrill_api_key_test","list_id_test")

    assert_difference('Club.count', 1) do
      click_link_or_button 'Create Club'
      assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    end
    assert page.has_content? "mailchimp_api_key_test"
    assert page.has_content? "mandrill_api_key_test"
    assert page.has_content? "list_id_test"

    club = Club.last
    assert club.mailchimp_mandrill_client?
    @admin_agent.update_attribute :roles, ''
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @admin_agent.id
    club_role.role = 'admin'
    club_role.save
        
    click_link_or_button('Edit')
    configure_mailchimp_mandrill("mailchimp_api_key_test_new","mandrill_api_key_test_new","list_id_test_new")
    click_link_or_button 'Update Club'
  end
end