require 'test_helper' 
 
class ClubTest < ActionController::IntegrationTest
 
  setup do
    init_test_setup
    @partner = FactoryGirl.create(:partner)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    FactoryGirl.create(:batch_agent)
    sign_in_as(@admin_agent)
  end


  ###########################################################
  # TESTS
  ###########################################################

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
    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?("Members")
      assert page.has_content?("Products")
      assert page.has_content?("Fulfillments")
    end
  end

  test "Should see every club on my clubs table when has agency role." do
    @admin_agent.update_attribute(:roles,['agency'])
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }

    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?("Members")
      assert page.has_content?("Products")
      assert page.has_content?("Fulfillments")
    end
  end

  test "Should see every club on my clubs table when has representative role." do
    @admin_agent.update_attribute(:roles,['representative'])
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }

    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?("Members")
      assert page.has_no_content?("Products")
      assert page.has_no_content?("Fulfillments")
    end
  end

  test "Should see every club on my clubs table when has supervisor role." do
    @admin_agent.update_attribute(:roles,['supervisor'])
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }

    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?("Members")
      assert page.has_no_content?("Products")
      assert page.has_no_content?("Fulfillments")
    end
  end

  test "Add a contact number by club" do
    @club = FactoryGirl.create(:simple_club_with_gateway, :name => "new_club", :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    
    unsaved_blacklisted_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_blacklisted_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @blacklisted_member = Member.find_by_email(unsaved_blacklisted_member.email)
    @blacklisted_member.blacklist(@admin_agent,"Testing")

    
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    fill_in_member(unsaved_member, credit_card)

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
    click_link_or_button 'members'
    assert page.has_no_content?("We're sorry, but something went wrong.")
  end
end