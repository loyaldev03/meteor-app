require 'test_helper'

class CreditCardsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agency_agent = FactoryGirl.create(:confirmed_agency_agent)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway
    @club = @terms_of_membership.club
    @partner = @club.partner
    @saved_member = FactoryGirl.create :member_with_api, :club_id => @terms_of_membership.club.id, :visible_id => 1
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @saved_member.id
    # request.env["devise.mapping"] = Devise.mappings[:agent]
  end

  def generate_post_message()
    post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.visible_id, 
                  credit_card: { :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }
  end  

  test "Should add a new credit_card" do
  	sign_in @admin_user
    
    cc_number = @active_credit_card.number
    
    @credit_card = FactoryGirl.build :credit_card_american_express
   
    assert_difference('Operation.count') do
      assert_difference('CreditCard.count',1) do
        generate_post_message()
      end
    end
    assert_response :success
    assert_equal(@saved_member.active_credit_card.number, @credit_card.number)
    assert_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
	end

  test "Should add a new credit_card with different year" do
    sign_in @admin_user
    
    cc_number = @active_credit_card.number
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @saved_member.active_credit_card.number
    @credit_card.expire_month = @saved_member.active_credit_card.expire_month

    assert_difference('Operation.count') do
      assert_difference('CreditCard.count',1) do
        generate_post_message()
      end
    end
    assert_response :success
    assert_equal(@saved_member.active_credit_card.number, @credit_card.number)
    assert_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
  end

  test "Should add a new credit_card with different month" do
    sign_in @admin_user
    
    cc_number = @active_credit_card.number
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @saved_member.active_credit_card.number
    @credit_card.expire_year = @saved_member.active_credit_card.expire_year

    assert_difference('Operation.count') do
      assert_difference('CreditCard.count',1) do
        generate_post_message()
      end
    end
    assert_response :success
    assert_equal(@saved_member.active_credit_card.number, @credit_card.number)
    assert_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
  end

  test "Should not add a new credit_card with invalid number" do
    sign_in @admin_user
    
    cc_number = @active_credit_card.number
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "123456"

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_post_message()
      end
    end
    assert_response :success
    assert_equal(@saved_member.active_credit_card.number, cc_number)
  end
  
  test "Should not add new credit card with same data as the one active" do
    sign_in @admin_user
    
    cc_number = @active_credit_card.number
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @saved_member.active_credit_card.number
    @credit_card.expire_year = @saved_member.active_credit_card.expire_year
    @credit_card.expire_month = @saved_member.active_credit_card.expire_month

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_post_message()
      end
    end
    assert_response :success
    assert_equal(@saved_member.active_credit_card.number, @credit_card.number)
    assert_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
  end
end
