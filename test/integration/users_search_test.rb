require 'test_helper'
 
class UsersSearchTest < ActionController::IntegrationTest

  transactions_table_empty_text = "No data available in table"
  operations_table_empty_text = "No data available in table"
  fulfillments_table_empty_text = "No fulfillments were found"
  communication_table_empty_text = "No communications were found"

  ############################################################
  # SETUP
  ############################################################

  setup do
    unstubs_elasticsearch_index
  end

  def setup_user(create_new_user = true)
    User.index.delete
    @default_state = "Alabama" # when we select options we do it by option text not by value ?
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    
    if create_new_user
      @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, :enrollment_info, {}, { :created_by => @admin_agent })
    end

    sign_in_as(@admin_agent)
   end

  #Only for search test
  def setup_search(create_new_users = true)
    setup_user false
    Delayed::Worker.delay_jobs = true
    if create_new_users
      20.times{ create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent }) }
      30.times{ create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, { :created_by => @admin_agent }) }
      30.times{ create_active_user(@terms_of_membership_with_gateway, :provisional_user, nil, {}, { :created_by => @admin_agent }) }
    end
    Delayed::Job.all.each{ |x| x.invoke_job }
    Delayed::Worker.delay_jobs = false

    @search_user = User.first
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  ##########################################################
  # TESTS
  ##########################################################

  test "search user by user id" do
    search_user("user[id]", "#{@search_user.id}", @search_user)
  end

  test "search user by first_name" do
    setup_search
    search_user("user[first_name]", "#{@search_user.first_name}", @search_user)
  end

  test "search user by last_name" do
    setup_search
    search_user("user[last_name]", "#{@search_user.last_name}", @search_user)
  end

  test "search user by email" do
    setup_search
    search_user("user[email]", "#{@search_user.email}", @search_user)
    search_user("user[email]", "#{@search_user.email.split('@').first}*", @search_user)
  end

  

end