require 'test_helper' 
 
class RolesTest < ActionController::IntegrationTest
 
  def setup_admin
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  def setup_supervisor
    init_test_setup
    @supervisor_agent = FactoryGirl.create(:confirmed_supervisor_agent)
    sign_in_as(@supervisor_agent)
  end

  def setup_representative
    init_test_setup
    @representative_agent = FactoryGirl.create(:confirmed_representative_agent)
    sign_in_as(@representative_agent)
  end

  def setup_agency
    init_test_setup
    @agency_agent = FactoryGirl.create(:confirmed_agency_agent)
    sign_in_as(@agency_agent)
  end

  def setup_member(create_new_member = true)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    end
   end

  test "select all clubs for admin agent."do
  	setup_admin
    partner = FactoryGirl.create(:partner)
    10.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    visit admin_agents_path
    within("#change_partner")do
      Club.all.each do |club|
        wait_until{ assert page.has_content?("#{club.partner.prefix} - #{club.name}") }
      end
    end
  end

  test "select only clubs related to supervisor agent."do
  	setup_supervisor
    partner = FactoryGirl.create(:partner)
    2.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    first_club = Club.first
    second_club = Club.last
    @supervisor_agent.add_role_with_club('supervisor', first_club)

    click_link_or_button("My Clubs")
    within("#change_partner")do
      wait_until{ assert page.has_content?("#{partner.prefix} - #{first_club.name}") }
      wait_until{ assert page.has_no_content?("#{partner.prefix} - #{second_club.name}") }
    end
  end

  test "select only clubs related to representative agent."do
  	setup_representative
    partner = FactoryGirl.create(:partner)
    2.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    first_club = Club.first
    second_club = Club.last
    @representative_agent.add_role_with_club('representative', first_club)

    click_link_or_button("My Clubs")
    within("#change_partner")do
      wait_until{ assert page.has_content?("#{partner.prefix} - #{first_club.name}") }
      wait_until{ assert page.has_no_content?("#{partner.prefix} - #{second_club.name}") }
    end
  end

  test "select only clubs related to agency agent."do
  	setup_agency
    partner = FactoryGirl.create(:partner)
    2.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    first_club = Club.first
    second_club = Club.last
    @agency_agent.add_role_with_club('representative', first_club)

    click_link_or_button("My Clubs")
    within("#change_partner")do
      wait_until{ assert page.has_content?("#{partner.prefix} - #{first_club.name}") }
      wait_until{ assert page.has_no_content?("#{partner.prefix} - #{second_club.name}") }
    end
  end

  test "Profile supervisor - See full CC" do
    setup_admin
    setup_member
    @admin_agent.roles = ['supervisor']
    @admin_agent.reload

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }
    within("#table_active_credit_card")do
      wait_until{ assert page.has_content?(@saved_member.active_credit_card.number.to_s) }
    end
    within(".nav-tabs") do
      click_on("Credit Cards")
    end
    within("#credit_cards")do
      wait_until{
        assert page.has_content?(@saved_member.active_credit_card.number.to_s)
      }
    end
  end

end