require 'test_helper'

class Api::ClubCashTransactionControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @agency_user = FactoryGirl.create(:confirmed_agency_agent)
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    @club = FactoryGirl.create(:club_with_api)
    @partner = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @wordpress_terms_of_membership = FactoryGirl.create :wordpress_terms_of_membership_with_gateway, :club_id => @club.id
    Drupal.enable_integration!
    Drupal.test_mode!
    Drupal::UserPoints.any_instance.stubs(:create!).returns('true')
  end

  test "admin should not add club cash transaction if domain is drupal" do
    sign_in @admin_user
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent }) 
    assert_difference('ClubCashTransaction.count', 0) do
      result = post(:create, { :member_id => @saved_member.id, 
                                club_cash_transaction: {
                                  :amount => 100, 
                                  :description => "adding club cash"
                                }, :format => :json })
    end
    assert_response :success
  end


  test "admin should add club cash transaction" do
    sign_in @admin_user
    @saved_member = create_active_member(@wordpress_terms_of_membership, :active_member, nil, {}, { :created_by => @admin_agent }) 
    @club.update_attribute :api_type, ''

    assert_difference('ClubCashTransaction.count') do
      result = post(:create, { :member_id => @saved_member.id, 
                                club_cash_transaction: {
                                    :amount => 100, 
                                  :description => "adding club cash"
                                }, :format => :json })
    end
    assert_response :success
  end

  test "representative should not add club cash transaction" do
    sign_in @representative_user
    @saved_member = create_active_member(@wordpress_terms_of_membership, :active_member, nil, {}, { :created_by => @admin_agent }) 

    assert_difference('ClubCashTransaction.count',0) do
      result = post(:create, { :member_id => @saved_member.id, 
                                club_cash_transaction: {
                                  :amount => 100, 
                                  :description => "adding club cash"
                                }, :format => :json })
    end
    assert_response :unauthorized
  end

  test "supervisor should add club cash transaction" do
    sign_in @supervisor_user
    @saved_member = create_active_member(@wordpress_terms_of_membership, :active_member, nil, {}, { :created_by => @admin_agent }) 
    @club.update_attribute :api_type, ''

    assert_difference('ClubCashTransaction.count') do
      result = post(:create, { :member_id => @saved_member.id, 
                                club_cash_transaction: {
                                  :amount => 100, 
                                  :description => "adding club cash"
                                }, :format => :json })
    end
    assert_response :success
  end

  test "agency should not add club cash transaction" do
    sign_in @agency_user
    @saved_member = create_active_member(@wordpress_terms_of_membership, :active_member, nil, {}, { :created_by => @admin_agent }) 

    assert_difference('ClubCashTransaction.count',0) do
      result = post(:create, { :member_id => @saved_member.id, 
                                club_cash_transaction: {
                                  :amount => 100, 
                                  :description => "adding club cash"
                                }, :format => :json })
    end
    assert_response :unauthorized
  end
end